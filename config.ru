require 'jd'
require 'rack/hoptoad'

use Rack::Hoptoad, '3a39c45459a77023d2d67be0cd6a78a6'
run Sinatra::Application
