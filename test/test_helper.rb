require "minitest/autorun"
require_relative "../lib/podcast_source_adapters"

FixtureTransport = Data.define(:responses, :requests) do
  def call(**request)
    requests << request
    response = responses.shift || raise("No fixture response")
    PodcastSourceAdapters::Http::Response.new(code: 200, body: response, headers: {})
  end
end

def fixture(name)
  File.read(File.join(__dir__, "fixtures", name))
end
