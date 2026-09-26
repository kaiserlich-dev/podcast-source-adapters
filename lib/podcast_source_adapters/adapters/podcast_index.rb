module PodcastSourceAdapters
  module Adapters
    class PodcastIndex
      ENDPOINT = "https://api.podcastindex.org/api/1.0/search/byperson"

      def initialize(queries:, api_key:, api_secret:, user_agent:, transport: Http.new, clock: -> { Time.now.to_i })
        raise ConfigurationError, "Podcast Index credentials are required" if api_key.to_s.empty? || api_secret.to_s.empty?
        raise ConfigurationError, "user_agent is required" if user_agent.to_s.empty?

        @queries, @api_key, @api_secret, @user_agent = queries, api_key, api_secret, user_agent
        @transport, @clock = transport, clock
      end

      def each_episode
        return enum_for(__method__) unless block_given?

        seen = {}
        @queries.each do |query|
          payload = fetch(query)
          items = payload["items"]
          raise ResponseError, "Podcast Index items must be an array" unless items.is_a?(Array)
          items.each do |item|
            episode = normalize(item)
            yield episode unless seen[episode.canonical_id]
            seen[episode.canonical_id] = true
          end
        end
      end

      private

      def fetch(query)
        timestamp = @clock.call.to_s
        signature = Digest::SHA1.hexdigest("#{@api_key}#{@api_secret}#{timestamp}")
        url = "#{ENDPOINT}?#{URI.encode_www_form(q: query, max: 100, fulltext: true)}"
        response = @transport.call(method: :get, url:, headers: {
          "User-Agent" => @user_agent, "X-Auth-Key" => @api_key,
          "X-Auth-Date" => timestamp, "Authorization" => signature
        })
        JSON.parse(response.body).tap do |json|
          raise ResponseError, "Podcast Index rejected the request" unless [ true, "true" ].include?(json["status"])
        end
      rescue JSON::ParserError => error
        raise ResponseError, "Invalid Podcast Index JSON: #{error.message}"
      end

      def normalize(item)
        provider_id = item.fetch("id").to_s
        Episode.new(
          canonical_id: "podcast_index:#{provider_id}", provider: "podcast_index", provider_id:,
          feed_id: item["feedId"]&.to_s || item["feedUrl"], guid: item["guid"],
          title: item.fetch("title"), description: item["description"].to_s,
          audio_url: item.fetch("enclosureUrl"), web_url: item["link"],
          published_at: parse_time(item["datePublished"]), duration_seconds: item["duration"]&.to_i
        )
      end

      def parse_time(value)
        value.is_a?(Numeric) ? Time.at(value).utc : Time.parse(value.to_s)
      rescue ArgumentError
        nil
      end
    end
  end
end
