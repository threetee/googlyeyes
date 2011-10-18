require 'rubygems'
require 'bundler'
Bundler.require

# For heroku logging
$stdout.sync = true

require File.join(File.dirname(__FILE__), 'lib', 'googlyeyes', 'app')

map '/' do
  run GooglyEyes::App
end

map '/magickly' do
  run Magickly::App
end
