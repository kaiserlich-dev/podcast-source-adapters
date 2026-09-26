require_relative "test_helper"

class EpisodeTest < Minitest::Test
  def test_new_show_fields_are_optional_for_existing_constructors
    episode = PodcastSourceAdapters::Episode.new(
      canonical_id: "rss:guid:123", provider: "rss", provider_id: nil,
      feed_id: "feed", guid: "guid", title: "Episode", description: "Description",
      audio_url: "https://example.com/episode.mp3", web_url: nil,
      published_at: nil, duration_seconds: nil
    )

    assert_nil episode.show_title
    assert_nil episode.feed_url
    assert_predicate episode, :frozen?
  end
end
