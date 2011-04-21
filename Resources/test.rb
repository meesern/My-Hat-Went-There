#!/usr/bin/ruby -w

require 'rubygems'
require 'xmpp4r-simple'
require 'hpricot'
require 'ocwitness'

#Gubbins to find bundled gems in Titanium.  use Gemfile and 'bundle' to add new ones.
begin
  root = File.expand_path(File.dirname(Titanium.App.getPath))
rescue
  root = File.dirname(__FILE__)
end
gem_path = File.join(root, '../', 'Resources','vendor','bundle','ruby','1.8')
Gem.use_paths(gem_path)

Titanium.API.log("**********************************************")

def fileChosen(filenames)
  Titanium.API.log filenames
end

#callback = Proc.new file
#Titanium.UI.openFileChooserDialog( lambda {|fs| fileChosen(fs)}, {
#  :multiple=> false,
#  :title=> "Select GPS file",
#  :types=> ['gpx'],
#  :typesDescription=> "GPS",
#  :path=> ".",
#  })

