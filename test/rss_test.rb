require_relative "test_helper"

class RssTest < Minitest::Test
  def test_guid_is_stable_and_enclosure_fallback_discards_query
    transport = FixtureTransport.new(responses: [ fixture("feed.xml") ], requests: [])
    episodes = PodcastSourceAdapters::Adapters::Rss.new(url: "https://show.example/feed", transport:).each_episode.to_a

    assert_equal 2, episodes.size
    assert_equal "rss:guid:#{Digest::SHA256.hexdigest('stable-episode-1')}", episodes.first.canonical_id
    assert_equal "rss:enclosure:#{Digest::SHA256.hexdigest('https://cdn.example/two.mp3')}", episodes[1].canonical_id
    assert_equal "A practical discussion.", episodes.first.description
    assert episodes.all?(&:frozen?)
  end
end
