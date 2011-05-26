
require 'rubygems'
require 'bundler/setup'
require 'xmpp4r-simple'
require 'time'
require 'thread'
require 'net/http'
require 'uri'

MAX_STANZA = (1<<16)-1

class OcWitness
  def initialize(opts = {})
    opts[:server]   ||= 'greenbean'
    opts[:ocname]   ||= 'whathappened'
    opts[:port]     ||= 80
    @report_type =  opts[:type]
    @username =  opts[:username]
    @server =    opts[:server]
    @password =  opts[:password]
    @ocname =    opts[:ocname]
    @html_port = opts[:port]
    @blob = Blob.new
    @mutex = Mutex.new
    connect if @report_type == 'xmpp'
    @run = true
    @thread = Thread.new do
      self.visit
      while(@run) do 
	sleep 1 
	self.visit 
      end
    end
  end

  def connect
    @im = Jabber::Simple.new(@username+"@"+@server,@password)
  end

  def connected?
    @im.connected?
  end

  def report(measurement, time = nil)
    time ||= 'now'
    #take any time and report in UTC ISO 8601
    t = Time.parse(time).utc.iso8601(0)

    #wrap the measurement up in the xml that OC requires
    report = "<t>#{t}</t><ment>#{measurement.inspect}</ment>"

    #Accumulate in a blob until it's time to send
    @mutex.synchronize {
      @blob.add!(report)
    }
  end

  def close
    flush
  end

  def flush
    @run=false
    @thread.join
  end

  protected
  def visit
    begin
      return if @blob.empty?
      puts "Something to send."
      @mutex.synchronize {
	@blob.send! { |b|
	  deliver_xmpp(b) if @report_type == 'xmpp'
	  deliver_html(b) if @report_type != 'xmpp'
	}
      }
    rescue
      #report any exception
      puts $!
      raise
    end
  end

  def deliver_xmpp(b)
    connect unless connected?
    @im.deliver(@ocname+"@"+@server, b) 
  end

  def deliver_html(b)
    #post http://server/file_a_report/aspect
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
    prox = Net::HTTP::Proxy(proxy_host,proxy_port,proxy_user,proxy_pass)
    puts "Opened Proxy #{prox.inspect}"
    prox.start(@server, @html_port) do |h|
      puts "Sending"
      sleep 1
      h.get('/'){|response| puts response }
      puts "Post"
      #post2 does not raise exceptions.  Nil headers, do nothing with response
      #aspect id (3) is bogus.
      h.post('/file_a_report/3', "data=#{b}", nil ) {|response| puts response } 
      puts "done."
    end
    puts "On way out"
  end

end

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

