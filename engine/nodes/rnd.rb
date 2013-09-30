
class HostsUpSrc < Source
  def spawn
    while true
      addr = mk_rnd_ip
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
    'rndup'
  end

  def self.descr()
    "generates some random IP address that is online now"
  end
end

class RndHostsSrc < Source
  def spawn
    addr = mk_rnd_ip
    job = Job.new
    job.ip = addr
    #sleep 0.5
    return job
  end

  def self.opname()
    'rndaddr'
  end

  def self.descr()
    "generates random IP address"
  end
end

register_node_class HostsUpSrc
register_node_class RndHostsSrc


