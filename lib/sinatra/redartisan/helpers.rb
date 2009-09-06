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
            RDiscount::new(string, :smart).to_html
          end
          
          def highlight(document)
            document.gsub(%r{<pre><code>(.*?)</code></pre>}m) do |match|
              Uv.parse(unescape_html($1), 'xhtml', 'ruby', false, 'twilight')
            end
          end
          
          def url(path)
            request.script_name + path
          end

          def body_id
            b_id = request.path_info.split('/')[1] || 'home'
            b_id.to_i == 0 ? b_id : 'blog' # numerical paths are considered blog posts
          end

          def unescape_html(string)
            string.to_s.gsub("&amp;", "&").gsub("&lt;", "<").gsub("&gt;", ">").gsub("&#39;", "'").gsub("&quot;", '"')
          end
          
          def current_page?(page_number)
            Integer(params['page']) == page_number
          end
        end
      end
    end
  end
  
  register RedArtisan::Helpers
end