require_relative '../lib/rack/middleware'

require 'rspec-power_assert'

RSpec::PowerAssert.example_assertion_alias :assert
RSpec::PowerAssert.example_group_assertion_alias :assert

require 'devtools/spec_helper'

require 'rack/test'
require 'rack/lint'
require 'rack/mock'

Dir['spec/middlewares/*.rb'].each do |file|
  name = File.basename file, '.rb'
  body = IO.read file

  eval %!
    class #{name}
      include Rack::Middleware
      #{body}
    end
  !
end

# The tests were mostly derived from
# https://github.com/rack/rack/tree/master/test

describe Rack::Middleware do
  def middleware app, *a, &b
    Rack::Lint.new described_class.new app, *a, &b
  end

  def request
    Rack::MockRequest.env_for
  end

  def app
    lambda { |env| [200, {}, "hello, "] }
  end

  describe Blank do
    it 'should create a Response only when necessary' do
      instance = described_class.new app
      instance.call request
      assert { instance.instance_variable_get(:@response) == nil }
    end
  end

  describe RequestResponse do
    it do
      mi = middleware(app) { 'wtf' }
      response = Rack::MockRequest.new(mi).delete('/')
      assert { response.body == "hello, delete delivered" }
      assert { response.headers['Content-Type'] == 'wtf' }
    end
  end

  describe ContentType do
    it "set Content-Type to default text/html if none is set" do
      headers = middleware(app).call(request)[1]
      assert { headers['Content-Type'] == 'text/html' }
    end

    it "set Content-Type to chosen default if none is set" do
      headers =
        middleware(app, 'application/octet-stream').call(request)[1]
      assert { headers['Content-Type'] == 'application/octet-stream' }
    end

    it "not change Content-Type if it is already set" do
      app = lambda { |env| [200, {'Content-Type' => 'foo/bar'}, "Hello, World!"] }
      headers = middleware(app).call(request)[1]
      assert { headers['Content-Type'] == 'foo/bar' }
    end

    it "detect Content-Type case insensitive" do
      app = lambda { |env| [200, {'CONTENT-Type' => 'foo/bar'}, "Hello, World!"] }
      headers = middleware(app).call(request)[1]
      headers = headers.to_a.select { |k,v| k.downcase == "content-type" }
      assert { headers ==  [["CONTENT-Type","foo/bar"]] }
    end

    it "not set Content-Type on 304 responses" do
      app = lambda { |env| [304, {}, []] }
      response = middleware(app, "text/html").call(request)
      assert { response[1]['Content-Type'] == nil }
    end
  end

  describe Logger do
    subject do
      lambda do |env|
        log = env['rack.logger']
        log.debug("Created logger")
        log.info("Program started")
        log.warn("Nothing to do!")

        [200, {'Content-Type' => 'text/plain'}, ["Hello, World!"]]
      end
    end

    it 'conforms to Rack::Lint' do
      errors = StringIO.new
      a = Rack::Lint.new Rack::Logger.new subject
      Rack::MockRequest.new(a).get('/', 'rack.errors' => errors)
      assert { errors.string.match /INFO -- : Program started/ }
      assert { errors.string.match /WARN -- : Nothing to do/ }
    end
  end
end
