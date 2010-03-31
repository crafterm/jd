JD_ROOT = File.expand_path(File.dirname(__FILE__)) unless defined?(JD_ROOT)
JD_CONTENT_ROOT = File.join(File.expand_path(File.dirname(__FILE__)), 'content') unless defined?(JD_CONTENT_ROOT)

require 'rubygems'
require 'sinatra'

require 'uuidtools'
require 'chronic'
require 'atom'

require 'lib/sinatra/redartisan/blog'
require 'lib/sinatra/redartisan/atom'
require 'lib/sinatra/redartisan/content'
require 'lib/sinatra/redartisan/helpers'
require 'lib/sinatra/redartisan/extensions'

module RedArtisan

  class App < Sinatra::Base
    set :public, 'public'
    enable :raise_errors
  end

end
