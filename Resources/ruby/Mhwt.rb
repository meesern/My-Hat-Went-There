#!/usr/bin/ruby -w
#Pure ruby cli call to ocwitness

require 'rubygems'
require 'bundler/setup'
require 'xmpp4r-simple'
require 'hpricot'
require 'ocwitness'
#require 'trollop'  #command line parsing

$logger = Logger.new(STDOUT)

$logger.info("My Hat Went There")

def myHat_uploadFile(file)

  # gpx file trackpoint format looks like:
  #<trkpt lat="52.401180267" lon="-1.465151310">
  #  <ele>16.479736</ele>
  #<time>2007-07-18T15:49:06Z</time>
  #</trkpt>

  #parse the xml file
  doc = File.open(file) { |f| Hpricot(f) }

  $logger.info("----Hpricot Loaded----")

  #collect all the 'trkpt' elements
  $coords = doc.search("//trkpt").map do |tp|
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

  $logger.info("----Mapped Coords----")

  $logger.info("Coords: #{$coords.length}")

  $logger.info("Connect to WhatHappened")

  $pushed = 0
  $length = $coords.length
  #Thread.new do
    begin
      $logger.info("----New Thread----")
      $logger.info("Uploading")
      while ($pushed < $length)
	myHat_push_reports
      end
      $coords = [] #attempt to free memory
      $logger.info("That's Where my Hat Went...")
    rescue
      #report any exception
      $logger.info $!
      raise
    end
  #end
end

def myHat_push_reports
  ssize = 50
  $logger.info("----#{ssize} Slice----")
    #:port   => 80,
    #:server => 'production.socksforlife.co.uk',
  $ocw = OcWitness.new({ 
    :username => 'hatlocation',
    :password => 'jabber',
    :port   => 3000,
    :type   => 'html',
    :server => 'greenbean',
    :ocname => 'whathappened'
  })

  $coords.slice($pushed,ssize).each do |coord|
    measurement = "<point><lat>#{coord[:lat]}</lat><lon>#{coord[:lon]}</lon><ele>#{coord[:ele]}</ele></point>"
    $ocw.report(measurement, coord[:time])
    $pushed += 1
  end

  $ocw.flush
end

# Upload each file
ARGV.each do |a|
  myHat_uploadFile(a)
end


