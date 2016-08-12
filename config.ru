require 'dashing'
require 'redis-objects'
require 'yaml'

configure do
  set :auth_token, 'YOUR_AUTH_TOKEN'

  helpers do
    def protected!
      # Put any authentication code you want in here.
      # This method is run before accessing any resource.
    end
  end
end

def redis?
  ENV.has_key? 'REDISTOGO_URL'
end

if redis?
  redis_uri = URI.parse(ENV['REDISTOGO_URL'])
  Redis.current = Redis.new(:host => redis_uri.host,
      :port => redis_uri.port,
      :password => redis_uri.password)

  set :history, Redis::HashKey.new('dashing-history')
elsif File.exists?(settings.history_file)
  set history: YAML.load_file(settings.history_file)
else
  set history: {}
end

map Sinatra::Application.assets_prefix do
  run Sinatra::Application.sprockets
end

run Sinatra::Application
