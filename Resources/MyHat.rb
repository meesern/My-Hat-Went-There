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

Titanium.API.log("Starting Ruby Module")

# Select a test file for now.
$filerel  = "../../My\ Hat\ gps/etrex-001.gpx"
$testfile = File.join(root,$filerel)

def fileChosen(filenames)
  Titanium.API.log filenames
  return unless filenames.length > 0
  filenames.each { |file| processFile(file) }
end

def processFile(filename)
  viewUpload(filename)
  uploadFile(filename)
end

def uploadFile(file)
  ti_file = Titanium.Filesystem.getFile(file)
  puts("*****************************************************************")
  AppReport("no file found") unless ti_file.isFile()

  # gpx file trackpoint format looks like:
  #<trkpt lat="52.401180267" lon="-1.465151310">
  #  <ele>16.479736</ele>
  #<time>2007-07-18T15:49:06Z</time>
  #</trkpt>

  #parse the xml file
  doc = open(ti_file.toString) { |f| Hpricot(f) }

  puts("-----------------------------------------------------------------")

  #collect all the 'trkpt' elements
  coords = doc.search("//trkpt").map do |tp|
    #elevation is the contents of the 'ele' element
    ele  = tp.at('ele').inner_html
    #time is the contents of the 'time' element
    time = tp.at('time').inner_html
    #latitude is the contents of the 'lat' attribute
    lat  = tp['lat']
    #longitude is the contents of the 'lon' attribute
    lon  = tp['lon'] 
    {:lat=>lat, :lon=>lon, :ele=>ele, :time=>time}
  end

  AppReport("Coords: #{coords.length}")

  AppReport("Connect to Jabber")
  ocw = OcWitness.new
  ocw.connect

  AppReport("Connected") if ocw.connected?

  coords.each do |coord|
    measurement = "<point><lat>#{coord[:lat]}</lat><lon>#{coord[:lon]}</lon><ele>#{coord[:ele]}</ele></point>"
    ocw.report(measurement, coord[:time])
  end

  AppReport("Reported") if ocw.connected?

  puts "That's Where my Hat Went..."
  sleep(1)

end

