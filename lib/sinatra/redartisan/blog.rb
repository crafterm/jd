module Sinatra
  module RedArtisan
    module Blog
      def self.registered(app)
        
        # GET /
        app.get '/' do
          erb :welcome
        end
        
        # GET /contact
        app.get '/contact' do
          erb :contact
        end
        
        # GET /blog
        app.get '/blog' do
          @posts = Content::Post.recent
          erb :blog
        end
                
        # GET /2009/05/12/comma-intro
        app.get '/:year/:month/:day/:title' do |year, month, day, title|
          @post = Content::Post.find_by_year_month_day_title(year, month, day, title)
          raise NotFound, 'No such post' unless @post
          erb :article
        end
        
        # POST /blog/2009/05/12/comma-intro/comments
        app.post '/:year/:month/:day/:title/comments' do
          # create comment and redirect to post, or use discuss feature
        end
        
        app.get '/atom.xml' do
          'atom to come here'
        end
                
      end
    end
  end
  
  register RedArtisan::Blog
end
