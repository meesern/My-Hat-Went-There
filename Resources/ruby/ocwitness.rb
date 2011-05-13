
require 'rubygems'
require 'bundler/setup'
require 'xmpp4r-simple'
require 'time'
require 'thread'

MAX_STANZA = (1<<16)-1

class OcWitness
  def initialize(opts = {})
    opts[:server]   ||= 'greenbean'
    opts[:ocname]   ||= 'whathappened'
    opts[:port]     ||= '3000'
    @report_type =  opts[:type]
    @username =  opts[:username]
    @server =    opts[:server]
    @password =  opts[:password]
    @ocname =    opts[:ocname]
    @html_port = opts[:port]
    @blob = Blob.new
    @mutex = Mutex.new
    Thread.new { loop { visit; sleep 0.2 }}
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
    visit
  end

  protected
  def visit
    return if @blob.empty?
    @mutex.synchronize {
      @blob.send! { |b|
        deliver_xmpp(b) if @report_type == 'xmpp'
        deliver_html(b) if @report_type != 'xmpp'
      }
    }
  end

  def deliver_xmpp(b)
    @im.deliver(@ocname+"@"+@server, b) 
  end

  def deliver_html(b)
    #post http://server/file_a_report/
    h = Net::HTTP.new(@server, @html_port)
    #post 2 does not raise exceptions.  Nil headers, do nothing with response
    h.post2('file_a_report', b, nil ) 
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

