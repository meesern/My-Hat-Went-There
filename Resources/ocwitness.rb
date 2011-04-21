require 'time'

class OcWitness
  
  def initialize(opts = {})
    opts[:username] ||= 'hatlocation'  #obviously needs to move out of OcWitness
    opts[:server]   ||= 'greenbean'
    opts[:password] ||= 'jabber'
    opts[:ocname]   ||= 'whathappened'
    $username =  opts[:username]
    $server =    opts[:server]
    $password =  opts[:password]
    $ocname =    opts[:ocname]
  end

  def connect
    $im = Jabber::Simple.new($username+"@"+$server,$password)
  end

  def connected?
    $im.connected?
  end

  def report(measurement, time = nil)
    time ||= 'now'
    #take any time and report in UTC ISO 8601
    t = Time.parse(time).utc.iso8601(0)

    #wrap the measurement up in the xml that OC requires
    report = "<t>#{t}</t><ment>#{measurement.inspect}</ment>"

    $im.deliver($ocname+"@"+$server,report)
  end

end

