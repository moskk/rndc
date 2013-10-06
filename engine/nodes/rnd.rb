
class HostsUpSrc < Source
  def spawn
    while true
      addr = mk_rnd_ip
      Thread.pass
      if online? addr
        job = Job.new
        job.ip = addr
        return job
      end
    end
=begin
    sleep 2
    job = Job.new
    job.ip = $example_addr
    puts job.ip
    return job
=end
  end

  def self.opname()
    ['rndup','SourceHostsUp']
  end

  def self.descr()
    "generates some random IP address that responds on ping requests"
  end
  
  def log_info()
    "generated random IP, ping'ed, got responce"
  end
end

class RndHostsSrc < Source
  def spawn
    addr = mk_rnd_ip
    job = Job.new
    job.ip = addr
    Thread.pass
    return job
  end

  def self.opname()
    ['rndaddr', 'SourceRndIP']
  end

  def self.descr()
    "generates random IP address"
  end
  
  def log_info()
    "generated random IP"
  end
end

register_node_class HostsUpSrc
register_node_class RndHostsSrc


