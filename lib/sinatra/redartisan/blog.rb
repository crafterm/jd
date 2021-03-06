module Sinatra
  module RedArtisan
    module Blog
      def self.registered(app)
        
        # GET /
        app.get '/' do
          @posts = options.repository.recent(3)
          erb :welcome
        end
        
        # GET /about
        app.get '/about' do
          @title = "About Red Artisan"
          erb :about
        end

        # GET /contact
        app.get '/contact' do
          @title = "Contact Details"
          erb :contact
        end
        
        # GET /blog
        app.get '/blog' do
          @posts = options.repository.paginated(Integer(params['page']))
          @pages = options.repository.total_pages
          erb :blog
        end
                
        # GET /2009/05/12/comma-intro
        app.get '/:year/:month/:day/:title' do |year, month, day, title|
          @post = options.repository.find_by_permalink(title)
          raise NotFound, 'No such post' unless @post
          @title = @post.title
          erb :article
        end

        # GET /2009/05/12/rubinius-intro/rubinius.pdf
        app.get '/assets/:year/:month/:day/:attachment' do |year, month, day, attachment|
          @attachment = options.repository.find_by_attachment(attachment)
          raise NotFound, 'No such attachment' unless @attachment
          send_file @attachment.content, :disposition => 'attachment'
        end
        
      end
    end
  end
  
  register RedArtisan::Blog
end
