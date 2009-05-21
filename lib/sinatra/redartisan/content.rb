require 'find'

module Sinatra
  module RedArtisan
    module Content
      
      def self.registered(app)
        app.configure do
          Find.find(JD_CONTENT_ROOT) do |path|
            if FileTest.directory?(path)
              meta = "#{path}/meta.rb"
              if File.exists?(meta)
                Post.register Post.new(meta)
                Find.prune
              end
            else
              next
            end
          end          
        end
      end
      
      class Post
        
        class << self
        
          def register(post)
            posts << post
            puts "Registered article #{post.path}"
          end
          
          def recent(count = 10)
            posts[0..count]
          end
        
          def find_by_year_month_day_title(year, month, day, title)
            posts.detect { |p| p.permalink == title && p.posted == "#{year}/#{month}/#{day}" }
          end
        
          def posts
            return @posts if @posts
            @posts = []
          end
          
        end
        
        def initialize(meta)
          @options = { :path => meta }
          instance_eval File.read(meta)
        end
        
        def article(name, &block)
          @options[:name] = name
          instance_eval &block
        end
        
        def content
          content_filename = File.join(File.expand_path(File.dirname(@options[:path])), 'content.markdown')
          File.read(content_filename)
        end
        
        def url
          "#{@options[:posted]}/#{@options[:permalink]}"
        end
        
        def attachments(*attachments)
          @options[:attachments] = attachments.collect { |a| Attachment.new(self, a) }
        end
        
        def method_missing(sym, *args, &block)
          return @options[sym] if args.empty?
          @options[sym] = args.size == 1 ? args.first : args
        end

        def [](key)
          @options[key]
        end        
      end
      
      class Attachment
        attr_accessor :article, :path, :permalink
        
        def self.find_by_year_month_day_title_attachment(year, month, day, title, attachment)
          @@attachments.detect { |a| a.permalink == "#{title}/#{attachment}" && a.article.posted == "#{year}/#{month}/#{day}" }
        end
        
        def initialize(article, name)
          @article = article
          @path = File.join(File.expand_path(File.dirname(article.path)), name)
          @permalink = "#{article.permalink}/#{name}"
          (@@attachments ||= []) << self
        end

      end
    end
  end
  
  register RedArtisan::Content
end


# #posts.year(year).month(month).day(day).title(title)
# 
# 
# # class << @@posts
# #   %w( year month day title permalink ).each do |attribute|
# #     define_method attribute do |reference|
# #       delete_if { |post| post[attribute.to_sym] != reference }
# #       self
# #     end
# #   end
# # end
