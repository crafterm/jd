Recently I've been doing lots of work with databases full of existing data and often have needed to extract data out to into YAML files to use either as bootstrap data (particularly images coming from attachment_fu that need to be preloaded after deployment) or as fixtures (yep, sometimes the data is just too complex to mock).

To ease the process I've created a script that I use inside of TextMate, which lets me convert a CSV exported file from CocoaMySQL to a YAML file, suitable for the db:bootstrap rake task or fixture data, all at the close distance of a keyboard shortcut.

First, to get the data out of the database, open up CocoaMySQL, select your table and view its content, and go to 'File -> Export -> Table Content Result -> Text File'.

<img src="http://redartisan.com/assets/2007/11/28/cocoamysql-export_1.png"/>

Save the exported contents.

Then you'll need the following script:

<filter:jscode lang="ruby">
#!/usr/bin/env ruby
#
# Format CSV output of cocoamysql into a fixture file
#
# "id","name","mime_type","extensions","icon_url"
# "1","unknown","unknown/unknown","||","/images/icon/file_unknown.gif"
# "2","image/tiff","image/tiff","|tiff|tif|","/images/icon/blank.png"

require 'csv'

class String
  def unquote
    self.gsub(/^"|"$/, '')
  end
end

# first line contains the field names
line = gets
fields = line.split('","').collect {|f| f.unquote.chomp}

CSV::Reader.parse(STDIN) do |row|
  fixture = "#{row[1].downcase}_#{row[0]}:\n"
  fields.each_with_index do |field, i|
    fixture += "  #{field}: #{row[i]}\n"
  end
  
  puts fixture; puts
end
</filter:jscode>

Which we'll add as a new 'Command' inside of a TextMate bundle.

To do this, open up TextMate, and select the 'Edit Commands' menu item

<img src="http://redartisan.com/assets/2007/11/28/textmate-edit-commands_1.png"/>

Then, in a custom bundle add a new command (+ button along the bottom of the dialog) and paste the contents of the script above.

<img src="http://redartisan.com/assets/2007/11/28/textmate-command-editor_1.png"/>

Select 'Entire Document' as the input source, and 'New Document' as the output, this will ensure that you don't overwrite your CSV file incase you require it later.

Then we need to reload the bundles so that TextMate knows about your new command. To do this, select the 'Reload Bundles' menu item

<img src="http://redartisan.com/assets/2007/11/28/textmate-reload-bundles_1.png"/>

And we're all set to go. Open up your CSV file, and convert it to a YAML file either via the keyboard shortcut defined in your Command (mine was ctrl-shift-cmd-F) or the menu item from your custom bundle and voila, a converted YAML document will appear which you can save directly to db/bootstrap or your fixtures directory. Enjoy.

