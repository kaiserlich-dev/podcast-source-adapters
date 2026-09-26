require "digest"
require "json"
require "net/http"
require "rss"
require "time"
require "uri"

require_relative "podcast_source_adapters/episode"
require_relative "podcast_source_adapters/http"
require_relative "podcast_source_adapters/adapters/rss"
require_relative "podcast_source_adapters/adapters/taddy"
require_relative "podcast_source_adapters/adapters/podcast_index"

module PodcastSourceAdapters
  Error = Class.new(StandardError)
  ConfigurationError = Class.new(Error)
  ResponseError = Class.new(Error)
end
