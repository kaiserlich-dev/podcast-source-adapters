# Podcast Source Adapters

A small Ruby package that normalizes RSS, Taddy, and Podcast Index results into one immutable episode contract. Adapters own transport details, bounded pagination, authentication headers, strict parsing, retries, URL normalization, and provider-scoped identities. Applications own relevance, persistence, deduplication policy across providers, transcription, publication, and UI.

```ruby
require "podcast_source_adapters"

source = PodcastSourceAdapters::Adapters::Rss.new(url: ENV.fetch("PODCAST_RSS_URL"))
source.each_episode { |episode| puts [episode.canonical_id, episode.title] }
```

All adapters accept an injectable `transport:` callable for deterministic tests. The default transport retries transient transport errors and HTTP 429/5xx responses with bounded exponential delay. It never retries authentication or malformed-response failures.

Provider credentials:

- Taddy: `user_id:` and `api_key:` become `X-USER-ID` and `X-API-KEY`.
- Podcast Index: `api_key:` and `api_secret:` sign `key + unix_time + secret` using SHA-1 and send the documented auth headers.

No product search terms, user agent, hostname, credentials, relevance prompt, or persistence policy is embedded.
