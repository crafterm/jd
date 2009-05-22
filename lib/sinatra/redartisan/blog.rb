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
          @posts = options.repository.recent
          erb :blog
        end
                
        # GET /2009/05/12/comma-intro
        app.get '/:year/:month/:day/:title' do |year, month, day, title|
          @post = options.repository.find_by_permalink(title)
          raise NotFound, 'No such post' unless @post
          erb :article
        end

        # GET /2009/05/12/rubinius-intro/rubinius.pdf
        app.get '/:year/:month/:day/:title/:attachment' do |year, month, day, title, attachment|
          @attachment = options.repository.find_by_attachment(attachment)
          raise NotFound, 'No such attachment' unless @attachment
          send_file @attachment.content, :disposition => 'attachment'
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
