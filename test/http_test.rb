require_relative "test_helper"

class HttpTest < Minitest::Test
  class SequenceHttp < PodcastSourceAdapters::Http
    attr_reader :calls

    def initialize(responses:, **options)
      super(**options)
      @responses = responses
      @calls = 0
    end

    private

    def request(**)
      @calls += 1
      @responses.shift
    end
  end

  def test_retries_transient_status_with_bounded_backoff
    response = PodcastSourceAdapters::Http::Response
    sleeps = []
    http = SequenceHttp.new(
      responses: [ response.new(code: 503, body: "", headers: {}), response.new(code: 200, body: "ok", headers: {}) ],
      sleeper: ->(seconds) { sleeps << seconds }
    )

    result = http.call(method: :get, url: "https://example.test")

    assert_equal "ok", result.body
    assert_equal 2, http.calls
    assert_equal [ 1 ], sleeps
  end

  def test_does_not_retry_authentication_failure
    response = PodcastSourceAdapters::Http::Response.new(code: 401, body: "", headers: {})
    http = SequenceHttp.new(responses: [ response ], sleeper: ->(*) { flunk("must not sleep") })

    assert_raises(PodcastSourceAdapters::ResponseError) do
      http.call(method: :get, url: "https://example.test")
    end
    assert_equal 1, http.calls
  end
end
