CSV can be quite uninspiring at times, but as I'm sure many of you are all too familiar, many modern applications still require parsing and generation of CSV to interface with legacy systems and/or desktop software, notably Excel. 

One of my Ruby on Rails clients required CSV data generation to support an 'export to excel' feature - so I embarked on a journey to look at the various CSV gems/plugins available at the time to export our data. 

The result of this adventure gave birth to [Comma](http://github.com/crafterm/comma), a small and simple (just over 60 lines implementation) gem that adds CSV generation support to arbitrary Ruby objects. 

Using a declarative approach, you specify the output CSV format naming attributes, methods, associations, etc, all within a block with optional header names. Comma traverses these definitions to fetch model data, with conventions inferring headers when not specified using sensible defaults.

I had a few particular requirements while researching, which led to Comma's development:


1. Support pure Ruby objects

    I wanted to export arbitrary instances to CSV, not just ActiveRecord derived objects, and hence didn't want to use a plugin specific to Rails, or one that had internal knowledge of ActiveRecord or similar models for inferring information such as associations and attributes.

2. Flexibility

    Transparency across associations, attributes and methods - they should all be treated the same. Some of the plugins I looked at required different configuration to name methods or associations to use, as opposed to attributes. I wanted to be able to cleanly define where the data for export should come from, and have Comma transparently access to it (after all, Ruby's #send mechanism provides the base foundations for this).
    
3. Multiple CSV output formats per class

    One class we have requires several CSV output formats, one for delivery to end users, and another for escrow purposes. I wanted to be able to define multiple output formats per class, and be able to call upon them when required.

4. Integration

    We're using Ruby on Rails, so integration with Rails would be useful, particularly at the controller level, which should be DRY and able to 'render :csv => @objects'.

3. Simplicity

    CSV export shouldn't be that hard on the plugin/gem implementer, nor the plugin/gem user - ideally I wanted to be able to define a CSV configuration (with an optional name) using a declarative syntax that names what should be exported, and have that same definition used for data access and header name generation.


An example use of Comma follows:


    class Book < ActiveRecord::Base

      # ================
      # = Associations =
      # ================
      has_many   :pages
      has_one    :isbn
      belongs_to :publisher

      # ===============
      # = CSV support =
      # ===============
      comma do

        name
        description

        pages :size => 'Pages'
        publisher :name
        isbn :number_10 => 'ISBN-10', :number_13 => 'ISBN-13'
        blurb 'Summary'

      end

    end


Annotated, the 'Comma' description includes:

    
    # starts a Comma description block, generating 2 methods #to_comma and #to_comma_headers for this class.
    comma do

      # name, description are attributes of Book with the header being reflected as 'Name', 'Description'
      name
      description

      # pages is an association returning an array, :size is called on the association results, with the header name specifed as 'Pages'
      pages :size => 'Pages'

      # publisher is an association returning an object, :name is called on the associated object, with the reflected header 'Name'
      publisher :name

      # isbn is an association returning an object, :number_10 and :number_13 are called on the object with the specified headers 'ISBN-10' and 'ISBN-13'
      isbn :number_10 => 'ISBN-10', :number_13 => 'ISBN-13'

      # blurb is an attribute of Book, with the header being specified directly as 'Summary'
      blurb 'Summary'

    end


Notice above how attributes and associations are all specified and treated the same, header names are reflected from the method names using sensible conventions unless provided directly, and more complex combinations of data can be grouped together into methods if required.

Multiple descriptions can be specified with a named Comma block:


    # ===============
    # = CSV support =
    # ===============
    comma do  # implicitly named :default

      name
      description

      pages :size => 'Pages'
      publisher :name
      isbn :number_10 => 'ISBN-10', :number_13 => 'ISBN-13'
      blurb 'Summary'

    end

    comma :brief do

      name
      description
      blurb 'Summary'

    end

You can specify which format you'd prefer as an optional parameter to #to_comma.
    
If you're using Ruby on Rails, your controllers automatically gain Comma-fu.


    class BooksController < ApplicationController

      def index
        respond_to do |format|
          format.csv { render :csv => Book.limited(50) }
        end
      end

    end


Comma is licensed under the MIT License, and can be installed directly from github's gem server.

    sudo gem install crafterm-comma

Please feel free to [contact](mailto:crafterm@redartisan.com) me if you have any questions and/or feedback regarding Comma.

