require 'rdiscount'
require 'uv'

module Sinatra
  module RedArtisan
    module Helpers
      
      def self.registered(app)
        app.helpers do
          include Rack::Utils
          alias_method :h, :escape_html
           
          def markup(string)
            RDiscount::new(string).to_html
          end
          
          def highlight(document)
            document.gsub(%r{<pre><code>(.*?)</code></pre>}m) do |match|
              Uv.parse($1, 'xhtml', 'ruby', false, 'twilight')
            end
          end
          
          def url(path)
            request.script_name + path
          end

          def body_id
            request.path_info.split('/')[1] || 'home'
          end
        end
      end
      
    end
  end
  
  register RedArtisan::Helpers
end