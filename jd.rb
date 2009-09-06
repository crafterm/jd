JD_ROOT = File.expand_path(File.dirname(__FILE__)) unless defined?(JD_ROOT)
JD_CONTENT_ROOT = File.join(File.expand_path(File.dirname(__FILE__)), 'content') unless defined?(JD_CONTENT_ROOT)

require 'rubygems'
gem 'sinatra-sinatra'
require 'sinatra'

require 'uuidtools'
require 'chronic'
require 'atom'

require 'lib/sinatra/redartisan/blog'
require 'lib/sinatra/redartisan/atom'
require 'lib/sinatra/redartisan/content'
require 'lib/sinatra/redartisan/helpers'


module RedArtisan
  
  class App < Sinatra::Default
    
    set :public, 'public'

  end
  
end
