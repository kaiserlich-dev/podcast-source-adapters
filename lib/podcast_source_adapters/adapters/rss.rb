module PodcastSourceAdapters
  module Adapters
    class Rss
      def initialize(url:, user_agent: "PodcastSourceAdapters/0.1", transport: Http.new)
        @url = url
        @user_agent = user_agent
        @transport = transport
      end

      def each_episode
        return enum_for(__method__) unless block_given?

        response = @transport.call(method: :get, url: @url, headers: { "User-Agent" => @user_agent })
        feed = RSS::Parser.parse(response.body, false)
        feed.items.each do |item|
          audio_url = item.enclosure&.url.to_s
          next if audio_url.empty?

          guid = item.guid&.content.to_s.strip
          yield Episode.new(
            canonical_id: Identity.rss(guid:, audio_url:), provider: "rss", provider_id: nil,
            feed_id: @url, guid: guid.empty? ? nil : guid, title: item.title.to_s.strip,
            description: plain_text(item.description), audio_url:, web_url: item.link,
            published_at: item.pubDate, duration_seconds: duration(item)
          )
        end
      rescue RSS::Error => error
        raise ResponseError, "Invalid RSS: #{error.message}"
      end

      private

      def plain_text(value)
        value.to_s.gsub(/<[^>]+>/, " ").gsub(/\s+/, " ").strip
      end

      def duration(item)
        value = item.respond_to?(:itunes_duration) ? item.itunes_duration&.content : nil
        parts = value.to_s.split(":").map(&:to_i)
        return if parts.empty?

        parts.reverse.each_with_index.sum { |part, index| part * (60**index) }
      end
    end
  end
end
