require "dalziel/version"
require "json_expressions"
require "webmock"

module Dalziel

  def self.format_headers(headers)
    size = headers.keys.map(&:size).max
    headers.map { |k,v| "%-#{size + 2}s %s" % [ "#{k}:", v ] }.join("\n")
  end

  def self.indent(string)
    string.split("\n").map { |line| "    #{line}" }.join("\n")
  end

  module Matchers

    # Stubs outgoing JSON requests with WebMock.
    #
    # Usage:
    #
    #     stub_json_request(:get, "url", user: { id: 1 })
    def stub_json_request(verb, url, body, status = 200)
      stub_request(verb, url).to_return(
        headers: { content_type: "application/json" },
        body: body.to_json,
        status: status,
      )
    end


    # Verifies outgoing request body stubbed with WebMock.
    #
    # Usage:
    #
    #     req = stub_json_request(:get, "url", user: { id: 1 })
    #
    #     act
    #
    #     expect(req).to match_json_request(
    #       foo: {
    #         bar: Integer
    #       }
    #     )
    def match_json_request(pattern)
      RequestMatcher.new(pattern)
    end

    # Verifies that the response is a proper JSON response.
    # Optionally you can chain `status` to verify the status code.
    #
    # Usage:
    #
    #     get "/foo/bar"
    #     expect(last_response).to match_json_response(
    #       foo: {
    #         bar: Integer
    #       }
    #     )
    def match_json_response(pattern)
      ResponseMatcher.new(pattern)
    end

    # Replacement for the json_expression default matcher, shows prettier output.
    #
    # Usage:
    #
    #     expect(json_or_hash).to match_json_expression(
    #       user: {
    #         id: Integer
    #       }
    #     )
    def match_json_expression(pattern)
      JSONPatternMatcher.new(pattern)
    end

    class JSONPatternMatcher

      attr_reader :json_expression, :request, :body

      def initialize(json_expression)
        @json_expression = json_expression
      end

      def does_not_match?(*)
        fail "Inverted matching is not implemented with this matcher"
      end

      def matches?(json)
        @original = json
        @hash = json.is_a?(String) ? JSON.parse(json) : json
        matcher =~ @hash
      rescue JSON::ParserError => error
        @not_parsable_json = error
        false
      end

      def failure_message
        if @not_parsable_json
          original = Dalziel.indent(@original.inspect)
          error = "#{@not_parsable_json.class}: #{@not_parsable_json}"
          "Couldn't parse the following:\n\n%s\n\n%s" % [ original, error ]
        else
          json = Dalziel.indent(JSON.pretty_generate(@hash))
          type = @original.is_a?(String) ? "JSON" : @original.class.to_s
          "Got the following %s:\n\n%s\n\n%s" % [ type, json, matcher.last_error ]
        end
      end

      private

      def matcher
        @matcher ||= JsonExpressions::Matcher.new(json_expression)
      end

    end

    class RequestMatcher

      attr_reader :json_expression, :request, :body

      def initialize(json_expression)
        @json_expression = json_expression
      end

      def matches?(request_pattern)
        @request = nil
        all_stubbed_requests.each { |request_signature, _count|
          if request_pattern.matches?(request_signature)
            @request = request_signature
            break
          end
        }
        return false if @request.nil?

        @body = JSON.parse(@request.body)
        @accept = @request.headers["Accept"]

        @is_json = @accept =~ /\bjson$/
        @json_match = payload_matcher =~ @body

        @is_json && @json_match
      end

      def does_not_match?(response)
        fail "Inverted matching is not implemented with this matcher"
      end

      def failure_message
        if @request.nil? || @request.empty?
          "No request matched"
        elsif !@is_json
          "Accept header is not JSON.\n\n%s\n\nAccept is %s" % [ show_request, @accept.inspect ]
        else
          "Request body did not match.\n\n%s\n\n%s" % [ show_request, payload_matcher.last_error ]
        end
      end

      def show_request
        headers = Dalziel.format_headers(request.headers)
        Dalziel.indent "%s %s\n\n%s\n\n%s" % [ request.method.to_s.upcase, request.uri.to_s, headers, JSON.pretty_generate(body) ]
      end

      def payload_matcher
        @payload_matcher ||= JsonExpressions::Matcher.new(json_expression)
      end

      def all_stubbed_requests
        WebMock::RequestRegistry.instance.requested_signatures
      end

    end

    class ResponseMatcher

      attr_reader :json_expression, :response, :body

      def initialize(json_expression)
        @json_expression = json_expression
        @status = 200
      end

      def matches?(response)
        @response = response
        @body = JSON.parse(response.body)
        @content_type = response.headers["Content-Type"]

        @is_json = (@content_type.to_s.split(";",2).first =~ /\bjson$/)
        @json_match = (payload_matcher =~ @body)
        @status_match = (@status == response.status)

        @status_match && @is_json && @json_match
      end

      def does_not_match?(response)
        fail "Inverted matching is not implemented with this matcher"
      end

      def failure_message
        if !@is_json
          "Content-Type is not JSON.\n\n%s\n\nContent-Type is %s" % [ show_response, @content_type.inspect ]
        elsif !@status_match
          "Unexpected response status.\n\n%s\n\nExpected response status to be %s, but was %s." % [ show_response, @status.inspect, response.status ]
        else
          "Response body did not match.\n\n%s\n\n%s" % [ show_response, payload_matcher.last_error ]
        end
      end

      def payload_matcher
        @payload_matcher ||= JsonExpressions::Matcher.new(json_expression)
      end

      def show_response
        headers = Dalziel.format_headers(response.headers)
        Dalziel.indent "HTTP/1.1 %s\n\n%s\n\n%s" % [ response.status, headers, JSON.pretty_generate(body) ]
      end

      def status(code)
        @status = code
        self
      end

    end

  end
end

if defined?(RSpec)
  RSpec.configure do |config|
    config.include Dalziel::Matchers
  end
end
