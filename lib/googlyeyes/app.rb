require File.join(File.dirname(__FILE__), '..', 'googlyeyes')
require 'sinatra/base'
require 'rack'
require 'rack/cache'
require 'redis-rack-cache'

module GooglyEyes
  class App < Sinatra::Base
    register Sinatra::Synchrony unless RUBY_VERSION.start_with? '1.8'
    
    DEMO_IMAGE = 'http://www.librarising.com/astrology/celebs/images2/QR/queenelizabethii.jpg'

    set :redis_url, ENV['REDISTOGO_URL'] || "redis://127.0.0.1:6379/0"

    set :static, true
    set :public, 'public'
        
    use Rack::Cache,
      :metastore   => "#{redis_url}/metastore",
      :entitystore => "#{redis_url}/entitystore"
    
    configure :production do
      require 'newrelic_rpm' if ENV['NEW_RELIC_ID']
    end
    
    before do
      app_host = ENV['GOOGLYEYES_APP_DOMAIN']
      if app_host && request.host != app_host
        request_host_with_port = request.env['HTTP_HOST']
        redirect request.url.sub(request_host_with_port, app_host), 301
      end
    end
    
    
    get %r{^/(\d+|rand)?$} do |eye_num|
      src = params[:src]
      if src
        # use the specified eye, otherwise fall back to random
        image = Magickly.process_src params[:src], :eyesify => (eye_num || true)
        image.to_response(env)
      else
        @eye_num = eye_num
        @site = Addressable::URI.parse(request.url).site
        haml :index
      end
    end
    
    get '/gallery' do
      haml :gallery
    end
    
    get '/test' do
      haml :test
    end
    
  end
end
