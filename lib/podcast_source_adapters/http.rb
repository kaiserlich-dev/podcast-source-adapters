module PodcastSourceAdapters
  class Http
    Response = Data.define(:code, :body, :headers)
    TRANSIENT = [ IOError, EOFError, SocketError, Errno::ECONNRESET, Errno::ETIMEDOUT, Net::OpenTimeout, Net::ReadTimeout ].freeze

    def initialize(retries: 2, sleeper: ->(seconds) { sleep(seconds) })
      @retries = retries
      @sleeper = sleeper
    end

    def call(method:, url:, headers: {}, body: nil)
      attempts = 0
      begin
        attempts += 1
        response = request(method:, url:, headers:, body:)
        return response if response.code.between?(200, 299)
        raise ResponseError, "HTTP #{response.code}" unless response.code == 429 || response.code >= 500
        raise ResponseError, "HTTP #{response.code}" if attempts > @retries

        @sleeper.call(2**(attempts - 1))
      rescue *TRANSIENT
        raise if attempts > @retries
        @sleeper.call(2**(attempts - 1))
      end while attempts <= @retries
    end

    private

    def request(method:, url:, headers:, body:)
      uri = URI(url)
      request = Net::HTTP.const_get(method.to_s.capitalize).new(uri)
      headers.each { |name, value| request[name] = value }
      request.body = body if body
      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: 10, read_timeout: 30) do |http|
        http.max_retries = 0
        raw = http.request(request)
        Response.new(code: raw.code.to_i, body: raw.body.to_s, headers: raw.to_hash)
      end
    end
  end
end
