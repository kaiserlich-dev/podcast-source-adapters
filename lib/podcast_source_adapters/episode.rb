module PodcastSourceAdapters
  Episode = Data.define(
    :canonical_id, :provider, :provider_id, :feed_id, :guid, :title,
    :description, :audio_url, :web_url, :published_at, :duration_seconds,
    :show_title, :feed_url
  ) do
    def initialize(show_title: nil, feed_url: nil, **attributes)
      super(show_title:, feed_url:, **attributes.freeze)
      raise ArgumentError, "canonical_id is required" if canonical_id.to_s.empty?
      raise ArgumentError, "title is required" if title.to_s.empty?
      raise ArgumentError, "audio_url must be HTTP(S)" unless audio_url.to_s.match?(%r{\Ahttps?://}i)
      freeze
    end
  end

  module Identity
    module_function

    def canonical_url(value)
      uri = URI.parse(value.to_s)
      raise ArgumentError, "URL must be HTTP(S)" unless %w[http https].include?(uri.scheme&.downcase)

      scheme = uri.scheme.downcase
      host = uri.host.to_s.downcase
      port = uri.port unless uri.default_port == uri.port
      path = uri.path.empty? ? "/" : uri.path
      "#{scheme}://#{host}#{":#{port}" if port}#{path}"
    end

    def rss(guid:, audio_url:)
      value = guid.to_s.strip
      kind, source = value.empty? ? [ "enclosure", canonical_url(audio_url) ] : [ "guid", value ]
      "rss:#{kind}:#{Digest::SHA256.hexdigest(source)}"
    end
  end
end
