require 'benchmark/ips'

require_relative '../lib/rack/middleware'
require_relative '../spec/app_from_file'
app_from_file File.expand_path 'spec/middlewares/ContentType.rb'

require 'rack'
Rack::ContentType

app = lambda { |env| [200, {}, "hello"] }
request = Rack::MockRequest.env_for


Benchmark.ips do |x|
  x.report('with Rack::Middleware') { ContentType.new(app).call request }
  x.report('without') { Rack::ContentType.new(app).call request }
  x.compare!
end
