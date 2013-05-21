$example_addr = '77.88.1.23'

require 'thread'
class Node
  @jobs = nil
  @cust_list = []
  # mode: true - result sent to all customers, false - result sent to any customer
  @mode = true
  @thread = nil
  def initialize(cust_list, mode = true)
    @jobs = Queue.new
    @cust_list = cust_list
    @mode = mode
    @thread = Thread.new{
      begin
        payload
      rescue => e
	puts "payload: some shit happened in #{self}:\n#{e.backtrace}"
      end
    }
  end
  
  def enq(job, from = nil)
    puts "#{from} -> #{self}: #{job}"
    @jobs.enq job
  end
  
  def payload
    "payload is not implemented for #{self}"
  end
  
  def pass(job)
    if(@mode)
     for cust in @cust_list
	cust.enq job
      end
    else
      l = len @cust_list
      return if l == 0
      to = rand l
      @cust_list[to].enq job
    end
  end
end

class Source < Node
  #remove_method :do_job
  
  def summoun
    sleep 0.5
    res = $example_addr
    puts "#{self} -> : #{res}"
    return res
  end
  
  def payload
    while true
      job = summoun
      next if not job
      pass job
    end
  end
end

class Filter < Node
  def payload
    while true
      job = @jobs.pop
      next if not job
      res = do_job job
      pass job if res
    end
  end
  
  def do_job(job)
    return true if job
    return false
  end
end

class Transformer < Node
  def payload
    while true
      job = @jobs.pop
      next if not job
      job = do_job job
      pass job if job
    end
  end
  
  def do_job(job)
    return job if job
    return nil
  end
end

def rndbyte()
  rand(255)
end

def mk_rnd_ip()
  while true
    first = rndbyte()
    if (first != 10) and (first != 127)
      return first.to_s + '.' + rndbyte.to_s + '.' + rndbyte.to_s + '.' + rndbyte.to_s
    end
  end
end

require 'net/ping'
def online?(host)
  res = Net::Ping::External.new.ping(host)
#   if res
#     stat = 'up'
#   else
#     stat = 'down'
#   end
#   puts "#{host} is #{stat}"
  return res
end

class HostsUpSrc < Source
  def summoun
    while true
      addr = mk_rnd_ip
      #puts addr
      return addr if online? addr
    end
  end
end

class PrintFlt < Filter
  def do_job(job)
    return true if job
    return false
  end
end

##########################################
#        E N T R Y   P O I N T
##########################################

#puts is_online mk_rnd_ip
f = Filter.new []
t = Transformer.new [f]
s = HostsUpSrc.new [t]
#f.enq example_addr
puts 'done!'
gets 

















