#!/usr/bin/ruby -w
#Pure ruby CLI call to ocwitness

require 'rubygems'
require 'bundler/setup'
require 'xmpp4r-simple'
#require 'hpricot'
require 'nokogiri'
require 'ocwitness'
#require 'trollop'  #command line parsing
require 'ruby-debug'

$logger = Logger.new(STDOUT)

$logger.info("Plate Tracker")

#
# Nokogiri to JSON helper
#
class Nokogiri::XML::Document
  def to_json(*a)
    root.to_json(*a)
  end
end
class Nokogiri::XML::Node
  def to_json(*a)
    {
      #:name => name,
      #:text => text,
      #:children => children.to_a,
    }.merge(attributes).to_json(*a)
  end
end
class Nokogiri::XML::Text
  def to_json(*a)
    text.to_json(*a)
  end
end
class Nokogiri::XML::Attr
  def to_json(*a)
    value.to_json(*a)
  end
end

#Manage the local cofiguration
class PlateSpinConfig
  def initialize(filename)
    @config = YAML::load(File.open(filename))
  end

  def server
    @config['storage']['server']
  end

  def port
    @config['storage']['port']
  end

  def item_name
    @config['storage']["itemname"] 
  end

  def item_id=(id)
    @config['storage']['itemid'] = id
  end

  def item_id
    @config['storage']['itemid']
  end

  def tableware
    @config['tableware']
  end
    
  def plate(code)
    @config['tableware'].find{|e| e['code'] == code}
  end

  def aspect(code)
    wname = self.plate(code)['name']
    ['aspects'][0]['id']
  end

  def entity_tree
    {'entities' => self.tableware.map{|e| {
        "name" => e['name'],
	"aspects" => @config['cameras'].map{|c| 
	    {"name"=>c['name']}
	}
    }}}
  end

  #This is all very very datastructury and not at all nice
  def entity_tree=(ids)
    @config['aspects'] ||= {}
    @config['cameras'].each do |camera|
      @config['aspects'][camera['streamid']] = {}
      @config['tableware'].each do |plate|
	@config['aspects'][camera['streamid']][plate['code']] = 
	  aspect_for(ids, plate['name'], camera['name'])
      end
    end
    puts @config.inspect
  end

  def aspect_for(ents, plate_name, camera_name)
    plate = ents['entities'].find{ |e| e['name'] == plate_name}
    aspect = plate['aspects'].find { |a| a['name'] == camera_name }
    aspect['id']
  end

  def aspects
    @config['aspects']
  end

end

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
    european_date = '%d/%m/%Y'
    date = Date.strptime(stream['date'], european_date).to_s
    stream.xpath("//marker").each do |marker|
      time = date + " " + marker['timestamp']
      box = [marker['x1'],marker['y1'],marker['x2'],marker['y2']]
      observation 'camera' => sid, 'code' => marker['code'], 'time' => time, 
	'box' => box, 'marker' => marker.to_json
    end
  end
end

# Receive an observation
# camera:	The id of the detecting camera
# code:		The dtouch code detected
# time:		The detection time (imprecise format)
# box:		The bounding box (array of x1,y1,x2,y2)
# marker:	The marker JSON (for storage)
def observation( obs )
  push_report :from => witnessid_for(obs['camera'].to_i), 
              :about => aspectid_for(obs['camera'].to_i,obs['code']), 
	      :at => obs['time'], 
              :sec => second_for(obs['time']),
	      :of => obs['marker'].to_s
end


def push_report( param )
  param[:from]  ||= 1        #default witness id
  param[:about] ||= 1        #fake aspect id
  param[:at]    ||= Time.now #report time
  param[:sec]||= 0.0
  param[:of]                 #measurement
  #pp param
  $ocw.report(param[:from], param[:about], param[:of], param[:at], param[:sec])
end

#Ensure that the Object Container has the tableware configured
def cloudconnect()
  #Get our item so we can use its id
  myItem = gettheitem()
  #Get the required entities
  entities = @psconfig.entity_tree
  #Ensure they exist on the cloud and update config with id's
  ids =  $ocw.createItemTree(entities, myItem['id'])
  @psconfig.entity_tree = ids
end

def gettheitem()
  #Get all accessible items
  items = $ocw.getItems  
  #Find ours by name
  myItem = items.detect{ |item| item["name"] == @psconfig.item_name }
  if myItem.nil?
    puts "Item #{@psconfig.item_name} does not exist.  Please create first."
    exit(-1)
  end
  myItem
end


def witnessid_for(stream_id)
  1
end

def second_for(time)
  # 29/6/10 10:32.750   => 0.750
  # 20/6/10 10:30       => 0.
  # Substitute everything not a dot until dot or end
  time.sub(/^[^.]*(\.|$)/,"0.")
end

def aspectid_for(sid,code)
  #sid is the camea
  #code is the plate
  #find the aspect...
  @psconfig.aspects[sid][code]
end

def usage_stop
  usage
  exit
end

def usage
puts <<USAGE


Usage:
  ./PlateTracker.rb <xml_file_to_upload> <xml_file_to_upload>*

  specify options for server etc. in colocated dinnerservice.yml

USAGE
end

###########################
#
#     Start Here....
#
###########################

usage_stop if ARGV.empty?

# Load the config
# {cameras => [{name =>.., streamid => ...}...]
#  tableware => [{name => ..., code => ..., markercount => ...}...]}
# hashes for cameras with stream id's and tableware with plates and codes
@psconfig = PlateSpinConfig.new('dinnerservice.yml')
#Do some options parsing for local or cloud
  #:port   => 80,
  #:server => 'production.socksforlife.co.uk',
$ocw = OcWitness.new({ 
  :username => 'hatlocation',
  :password => 'jabber',
  :port   =>  @psconfig.port,
  :type   => 'html',
  :server => @psconfig.server,
  :ocname => 'whathappened'
})

cloudconnect()

# Precess each file on the command line
ARGV.each do |a|
  processFile(a)
end

# Wait around for the upload to complete
# This could be long and the join can time out
$ocw.flush


