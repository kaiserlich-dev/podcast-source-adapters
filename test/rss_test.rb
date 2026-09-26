require_relative "test_helper"

class RssTest < Minitest::Test
  def test_guid_is_stable_and_enclosure_fallback_discards_query
    transport = FixtureTransport.new(responses: [ fixture("feed.xml") ], requests: [])
    episodes = PodcastSourceAdapters::Adapters::Rss.new(url: "https://show.example/feed", transport:).each_episode.to_a

    assert_equal 2, episodes.size
    assert_equal "rss:guid:#{Digest::SHA256.hexdigest('stable-episode-1')}", episodes.first.canonical_id
    assert_equal "rss:enclosure:#{Digest::SHA256.hexdigest('https://cdn.example/two.mp3')}", episodes[1].canonical_id
    assert_equal "Example", episodes.first.show_title
    assert_equal "https://show.example/feed", episodes.first.feed_url
    assert episodes.all?(&:frozen?)
  end

  def test_description_is_decoded_plain_text
    transport = FixtureTransport.new(responses: [ fixture("feed.xml") ], requests: [])

    episode = PodcastSourceAdapters::Adapters::Rss.new(
      url: "https://show.example/feed", transport:
    ).each_episode.first

    assert_equal "A practical discussion & recovery. Next line.", episode.description
  end
end
