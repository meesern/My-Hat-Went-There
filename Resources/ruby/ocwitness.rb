
require 'rubygems'
require 'bundler/setup'
require 'xmpp4r-simple'
require 'time'
require 'thread'
require 'net/http'
require 'uri'
require 'json'
require 'xmlsimple'

MAX_STANZA = (1<<16)-1   #max XMPP stanza / HTML post

class OcWitness
  def initialize(opts = {})
    opts[:server]   ||= 'greenbean'    #localhost name
    opts[:ocname]   ||= 'whathappened' #jabber id
    opts[:port]     ||= 80
    @report_type =  opts[:type]
    @username =  opts[:username]
    @server =    opts[:server]
    @password =  opts[:password]
    @ocname =    opts[:ocname]
    @html_port = opts[:port]
    #Blob's colate measurements avoid 1 message per measurement
    @blob = {}
    @mutex = Mutex.new
    connect if @report_type == 'xmpp'
    @run = true
    #start visiting the poller every half second to see if there is anything
    #to send
    @thread = Thread.new do
      self.visit
      while(@run) do 
	sleep 0.5 
	self.visit 
      end
    end
  end

  #depricated
  def connect
    @im = Jabber::Simple.new(@username+"@"+@server,@password)
  end

  def connected?
    @im.connected?
  end

  #######################
  # Get the items accessible
  # to the current user
  def getItems
    #get http://server/items
    items = {}
    html do |h|
      resp = h.get('/v1/items/', nil )
      case resp
      when Net::HTTPSuccess
	puts resp.body
	items = xml2obj(resp.body)['items']
      else
	unexpected(resp.class)
      end
    end
    items
  end

  #######################
  # Create an item in the cloud
  def createItemTree(hash, itemid)
    xml = obj2xml(hash, "entities")
    #post http://server/items
    items={}
    html do |h|
      resp = h.post("/v1/items/#{itemid}", "data=#{xml}", nil )
      case resp
      when Net::HTTPSuccess
	puts resp.body
	items = xml2obj(resp.body)['entities']
      else
	unexpected(resp.class)
      end
    end
    items
  end

  def xml2obj(blob)
    XmlSimple.xml_in(blob, "ForceArray" => false)
  end

  def obj2xml(hash, name)
    XmlSimple.xml_out(hash, "RootName"=>'entities',
		            "NoAttr"=>true).tap{|x| puts x.inspect}
  end

  def unexpected(message)
    raise "Got unexpected response #{message}."  
  end

  #######################
  # File a report
  #
  # from:  witness id
  # about: aspect id
  # measurement: xml fragment
  # time:  unformatted time of measurement
  #
  def report(from, about, measurement, time = nil)
    time ||= 'now'
    #take any time and report in UTC ISO 8601
    t = Time.parse(time).utc.iso8601(0)

    #wrap the measurement up in the xml that OC requires
    report = "<ment t='#{t}'>#{measurement}</ment>"

    #Accumulate in a blob until it's time to send
    @mutex.synchronize do
      #create the array of blobs-to-report on the fly
      @blob[from] ||= {}
      @blob[from][about] ||= Blob.new
      @blob[from][about].add!(report)
    end
  end

  #Alias for flush
  def close
    flush
  end

  #Send out all queued data and terminate the blob thread
  def flush
    @run=false
    @thread.join 
  end

  protected
  def visit
    @blob.each_pair do |from, hash|
      hash.each_pair do |about, blob|
	next if blob.empty?
	puts "Something to send"
	@mutex.synchronize {
	  blob.send! { |b|
	    deliver_xmpp(b, from, about) if @report_type == 'xmpp'
	    deliver_html(b, from, about) if @report_type != 'xmpp'
	  }
	}
      end
    end
  rescue
    # Report any exception
    # Needed for Debug as the thread context seems to soak up
    # the usual exception processing
    puts $!
    raise
  end

  def deliver_xmpp(b, from, about)
    connect unless connected?
    @im.deliver(@ocname+"@"+@server, b) 
  end

  def html_proxy
    puts "Parsing proxy"
    uri = URI.parse(ENV['http_proxy'])
    proxy_user = proxy_pass = nil
    proxy_user, proxy_pass = uri.userinfo.split(/:/) if uri.userinfo
    proxy_host = uri.host
    proxy_host = nil if (proxy_host.empty?)
    #no proxy if the server name is a local name (not domain.tld)
    proxy_host = nil if (@server.split('.').length < 2)
    proxy_port = uri.port || 8080
    puts "Delivering to server #{proxy_host}:#{proxy_port.to_s}->#{@server}:#{@html_port.to_s}"
    [proxy_host, proxy_port, proxy_user, proxy_pass]
  end

  ###########################
  # Send to Object Container
  #
  ###########################
  def deliver_html(b, from, about)
    #NOTE Ignoring from(witness) for now
    #post http://server/v1/file_a_report/aspect
    html do |h|
      puts "Post"
      #post2 does not raise exceptions. nil headers 
      h.post("/v1/file_a_report/#{about}", "data=#{b}", nil ) {|response| 
	puts "got response" } 
    end
  end

  def html
    phost,pt,pu,pp = html_proxy
    prox = Net::HTTP::Proxy(phost,pt,pu,pp)
    puts "Opened Proxy #{prox.inspect}"
    prox.start(@server, @html_port) do |h|
      yield(h)
    end
  end
end


####################
#  Blob class
#  Collate reports that are close in time.
#  The aim is to limit sends to a few a second
#

class Blob
  def initialize
    empty!
  end
  
  def empty?
    @chunk.empty? && @chunks.empty?
  end

  def add!(data)
    return if data.empty?
    chunk! if (@chunk.length + data.length > MAX_STANZA)
    @chunk << data
  end

  def send!
    chunk!
    @chunks.each { |blob| 
      yield blob
    }
    empty!
  end

  protected
  def chunk!
    @chunks << @chunk
    @chunk = ""
  end

  def empty!
    @chunks = []
    @chunk = ""
  end
end

