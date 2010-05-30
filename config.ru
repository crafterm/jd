require 'uv'
require 'rack/codehighlighter'
require 'rack/hoptoad'

require 'jd'

use Rack::Hoptoad, '3a39c45459a77023d2d67be0cd6a78a6'

use Rack::Codehighlighter, :ultraviolet,
                           :markdown => true,
                           :element  => "pre>code",
                           :pattern  => /\A:::(.*?)\s*(\n|&#x000A;)/i,
                           :logging  => false,
                           :themes   => {'twilight' => ['objective-c', 'ruby']}

run Sinatra::Application
