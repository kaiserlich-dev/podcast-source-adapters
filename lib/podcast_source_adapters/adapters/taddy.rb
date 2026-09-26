module PodcastSourceAdapters
  module Adapters
    class Taddy
      ENDPOINT = "https://api.taddy.org"
      QUERY = <<~GRAPHQL.freeze
        query($term: String!, $page: Int!, $limit: Int!) {
          search(term: $term, filterForTypes: PODCASTEPISODE, matchBy: EXACT_PHRASE,
            page: $page, limitPerPage: $limit) {
            searchId responseDetails { id type totalCount pagesCount }
            podcastEpisodes { uuid name description datePublished duration audioUrl websiteUrl guid
              podcastSeries { uuid name rssUrl } }
          }
        }
      GRAPHQL

      def initialize(queries:, user_id:, api_key:, transport: Http.new, page_limit: 10, per_page: 25)
        raise ConfigurationError, "Taddy credentials are required" if user_id.to_s.empty? || api_key.to_s.empty?

        @queries, @user_id, @api_key, @transport = queries, user_id, api_key, transport
        @page_limit, @per_page = page_limit, per_page
      end

      def each_episode
        return enum_for(__method__) unless block_given?

        seen = {}
        @queries.each do |term|
          page = 1
          loop do
            search = fetch(term, page)
            pages = pages_count(search)
            raise ResponseError, "Taddy result exceeds page limit #{@page_limit}" if pages > @page_limit
            Array(search["podcastEpisodes"]).each do |item|
              episode = normalize(item)
              yield episode unless seen[episode.canonical_id]
              seen[episode.canonical_id] = true
            end
            break if page >= pages
            page += 1
          end
        end
      end

      private

      def fetch(term, page)
        response = @transport.call(method: :post, url: ENDPOINT, headers: {
          "Content-Type" => "application/json", "X-USER-ID" => @user_id, "X-API-KEY" => @api_key
        }, body: { query: QUERY, variables: { term:, page:, limit: @per_page } }.to_json)
        json = JSON.parse(response.body)
        raise ResponseError, "Taddy GraphQL error" if json["errors"]&.any?
        json.dig("data", "search") || raise(ResponseError, "Missing Taddy search response")
      rescue JSON::ParserError => error
        raise ResponseError, "Invalid Taddy JSON: #{error.message}"
      end

      def normalize(item)
        provider_id = item.fetch("uuid")
        series = item.fetch("podcastSeries")
        Episode.new(
          canonical_id: "taddy:#{provider_id}", provider: "taddy", provider_id:,
          feed_id: series["uuid"], guid: item["guid"], title: item.fetch("name"),
          show_title: series["name"], feed_url: series["rssUrl"],
          description: item["description"].to_s, audio_url: item.fetch("audioUrl"),
          web_url: item["websiteUrl"], published_at: Time.parse(item["datePublished"].to_s),
          duration_seconds: item["duration"]&.to_i
        )
      rescue ArgumentError => error
        raise ResponseError, "Invalid Taddy episode: #{error.message}"
      end

      def pages_count(search)
        details = search["responseDetails"]
        raise ResponseError, "Taddy responseDetails must be an array" unless details.is_a?(Array)

        episode_details = details.find { |detail| detail["type"] == "PODCASTEPISODE" }
        episode_details ||= details.first if details.one?
        raise ResponseError, "Missing Taddy podcast episode pagination" unless episode_details

        Integer(episode_details.fetch("pagesCount"))
      rescue KeyError, TypeError, ArgumentError
        raise ResponseError, "Missing Taddy podcast episode pagination"
      end
    end
  end
end
