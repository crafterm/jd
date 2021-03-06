module Sinatra
  module RedArtisan
    module Atom
      def self.registered(app)

        app.get '/feed/blog/atom.xml' do
          headers 'Content-Type'  => "application/atom+xml",
                  'Cache-Control' => 'public, max-age=1800'

          feed = ::Atom::Feed.new do |f|
            f.title = 'Red Artisan - Blog'
            f.links << ::Atom::Link.new(:href => 'http://redartisan.com/blog')
            f.updated = options.repository.latest.posted.to_s(:iso8601)
            f.authors << ::Atom::Person.new(:name => 'Marcus Crafter')
            f.id = 'tag:redartisan.com,2009:jd/blog'

            options.repository.recent(15).each do |post|
              entry = ::Atom::Entry.new do |e|
                e.title = post.title
                e.links << ::Atom::Link.new(:href => post.url)
                e.id = UUIDTools::UUID.sha1_create(UUIDTools::UUID_URL_NAMESPACE, post.url).to_uri.to_s
                e.updated = post.posted.to_s(:iso8601)
                e.content = ::Atom::Content::Html.new(markup(File.read(post.content)))
              end

              f.entries << entry
            end
          end

          feed.to_xml
        end

      end
    end
  end

  register RedArtisan::Atom
end
