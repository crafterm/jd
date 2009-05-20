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
            puts "registered #{post.inspect}"
          end
          
          def recent(count = 10)
            posts[0..count]
          end
        
          def find_by_year_month_day_title(year, month, day, title)
            posts.detect { |p| p[:year] == year && p[:month] == month && p[:day] == day && p[:title] == title }
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
        
        def method_missing(sym, *args, &block)
          return @options[sym] if args.empty?
          @options[sym] = args.size == 1 ? args.first : args
        end

        def [](key)
          @options[key]
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