require_relative "test_helper"

class TaddyTest < Minitest::Test
  def test_paginates_with_authentication_and_namespaced_identity
    transport = FixtureTransport.new(
      responses: [ fixture("taddy-page-1.json"), fixture("taddy-page-2.json") ], requests: []
    )
    adapter = PodcastSourceAdapters::Adapters::Taddy.new(
      queries: [ "person" ], user_id: "user", api_key: "key", transport:
    )

    episodes = adapter.each_episode.to_a
    assert_equal %w[taddy:episode-a taddy:episode-b], episodes.map(&:canonical_id)
    assert_equal [ 1, 2 ], transport.requests.map { |request| JSON.parse(request.fetch(:body)).dig("variables", "page") }
    assert transport.requests.all? { |request| request.fetch(:headers).fetch("X-USER-ID") == "user" }
    assert_equal "series-a", episodes.first.feed_id
    assert_equal "Taddy Show", episodes.first.show_title
    assert_equal "https://show.example/feed.xml", episodes.first.feed_url
  end
end
