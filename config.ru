begin
  # Require preresolved locked gems
  require ::File.expand_path('.bundle/environment', __FILE__)
rescue LoadError
  # Fallback on resolving at runtime
  require 'rubygems'
  require 'bundler'
  Bundler.setup
end

require 'sinatra'
require 'oauth2'
require 'json'
require 'open-uri'
require 'mongo_mapper'
require 'foursquare2'

require File.join(File.dirname(__FILE__), 'models.rb')
require File.join(File.dirname(__FILE__), 'main.rb')

run App
