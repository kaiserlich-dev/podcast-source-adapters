require_relative "test_helper"

class PodcastIndexTest < Minitest::Test
  def test_signs_and_normalizes_results
    transport = FixtureTransport.new(responses: [ fixture("podcast_index.json") ], requests: [])
    adapter = PodcastSourceAdapters::Adapters::PodcastIndex.new(
      queries: [ "person" ], api_key: "key", api_secret: "secret", user_agent: "Example/1.0",
      transport:, clock: -> { 123 }
    )

    episodes = adapter.each_episode.to_a
    assert_equal 1, episodes.size
    episode = episodes.first
    request = transport.requests.first
    assert_equal "podcast_index:42", episode.canonical_id
    assert_equal Digest::SHA1.hexdigest("keysecret123"), request.fetch(:headers).fetch("Authorization")
    assert_includes request.fetch(:url), "q=person"
  end
end
