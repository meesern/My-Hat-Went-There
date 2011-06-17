#!/usr/bin/ruby -w
#Pure ruby CLI call to ocwitness

require 'rubygems'
require 'bundler/setup'
require 'xmpp4r-simple'
#require 'hpricot'
require 'nokogiri'
require 'ocwitness'
#require 'trollop'  #command line parsing

$logger = Logger.new(STDOUT)

$logger.info("Plate Tracker")

#
# Open an xml file with collected vision system data
#
def processFile(file)
  #streams:  	The collection of different webcams
  #stream:   	A webcam with it's own co-ordinates making a witness
  #marker:   	A measurement with data as attributes
  #timestamp:	Time code (missing date)
  #code:	The dtouch code
  #x1,y1,x2,y2:	bounding box for feducial marker
  #
  #<streams>
  #   <stream date="11/05/2011" id="0001">
  #     <marker timestamp="12:08:19.440" code="1:1:2" x1="295" y1="198" x2="395" y2="272" />

  #parse the xml file
  doc = File.open(file) { |f| Nokogiri::XML(f) }
  $logger.info("----Hpricot Loaded----")

  codes = doc.xpath("//marker").map{|m| m['code']}.uniq.sort
  puts "#{codes.length} distinct codes"

  #Generate a histogram of code vs frequency (for debug)
  #hist = codes.map{ |code| 
  #  [code, doc.xpath("//marker[@code='#{code}']").length] }
  #hist.sort!{|a,b| a[1]<=>b[1]}
  #hist.each{ |h| puts "#{h[0]}\n#{'='*h[1]}" }
  #exit

  doc.xpath("//stream").each do  |stream|
    sid = stream['id'] 
    date = stream['date'].tap{|x| pp x}
    stream.xpath("//marker").each do |marker|
      time = date + marker['timestamp']
      box = [marker['x1'],marker['y1'],marker['x2'],maker['y2']]
      observation :camera => sid, :code => marker['code'], :time => time, 
	:box => box, :marker => marker.to_s
    end
  end
end

# Receive an observation
# camera:	The id of the detecting camera
# code:		The dtouch code detected
# time:		The detection time (imprecise format)
# box:		The bounding box (array of x1,y1,x2,y2)
# marker:	The marker xml (for storage)
def observation( obs )
  push_report :from => witnessid_for(sid), :about => aspectid_for(sid,code), 
	       :at => time, :of => marker.to_s
end

def witnessid_for(stream_id)
  1
end

def aspectid_for(sid,code)
  @config['tableware'].find{|e| e.code == code}.aspectid
end

def push_report( param )
  param[:from]  ||= 1        #default witness id
  param[:about] ||= 1        #fake aspect id
  param[:at]    ||= Time.now #report time
  param[:of]                 #measurement
  measurement = param[:of]
  #pp param
  #$ocw.report(witness_id, attribute_id, measurement, param[:at])
end


#Do some options parsing for local or cloud
  #:port   => 80,
  #:server => 'production.socksforlife.co.uk',
$ocw = OcWitness.new({ 
  :username => 'hatlocation',
  :password => 'jabber',
  :port   =>  3000,
  :type   => 'html',
  :server => 'greenbean',
  :ocname => 'whathappened'
})

#Ensure that the Object Container has the tableware configured
def cloudconnect(config)
  items = $ocw.getItems  
  myItem = items.find{ |item| item["name"] == config['storage']["itemname"] }
  myItem ||= $ocw.itemCreate
  config['storage']['itemid'] = myItem['id']
  config['tableware'].each{ |e| registerEntity(e) }
end


###########################
#
#     Start Here....
#
###########################

# Load the config
# {cameras => [{name =>.., streamid => ...}...]
#  tableware => [{name => ..., code => ..., markercount => ...}...]}
# hashes for cameras with stream id's and tableware with plates and codes
@config = YAML::load(File.open('dinnerservice.yml'))
cloudconnect(@config)

# Precess each file on the command line
ARGV.each do |a|
  processFile(a)
end

# Wait around for the upload to complete
# This could be long and the join can time out
$ocw.flush



