#! /usr/bin/ruby

#$example_addr = '74.125.232.206'
$example_addr = '77.88.21.3'
#$example_addr = '66.71.253.245'

require 'ostruct'
class Job < OpenStruct
  def url
    res = '---'
    if not domain.nil?
      res = domain[0]
    else
      res = ip
    end
    #print self, ' url = ', res
    return res
  end
end

class EndOfJobStream
  #And I heard a voice in the midst of the four beasts
  #And I looked and behold, a pale horse
  #And his name that sat on him was Death
  #And Hell followed with him.
end

def print_error(e)
  puts "payload: shit happened in #{self}: #{e.message}\n"
  e.backtrace.each{|line| puts "\t#{line}"}
end

require 'thread'
class Node
  attr_accessor :invert
  attr_accessor :nodename
  attr_reader :thread
  attr_reader :cust_list
  attr_reader :ncust_list
  @jobs = nil
  @cust_list = []
  @ncust_list = []
  # mode: true - result sent to all customers, false - result sent to any customer
  @mode = true
  @thread = nil
  @invert = false
  def initialize(cust_list, ncust_list, mode, params = nil)
    @jobs = Queue.new
    @cust_list = cust_list
    @ncust_list = ncust_list
    @mode = mode
    @invert = false
    @nodename = ""
  end
  
  # enqueueing new job
  def enq(job, from = nil)
    if ready?
      @jobs.enq job
      return true
    else
      return false
    end
  end
  
  # common procedure of jobs processing
  def payload
    raise "payload is not implemented for #{self}"
  end
  
  # passing the successfully processed job to customer(s)
  def pass(job, succ)
    #puts "obj to pass #{job.inspect} from #{self}"
    if job.is_a? EndOfJobStream
      @cust_list.each{|cust|cust.enq job}
      @ncust_list.each{|cust|cust.enq job}
      puts "end of #{self.nodename} reached"
      return true
    elsif job.is_a? Job
      recv_list = succ ? @cust_list : @ncust_list
      if(@mode)
        #recv_list.each{|cust|cust.enq job}
        l = [].concat recv_list
        while not l.empty? do
          l.delete_if{|node|node.enq job}
        end
      else
        l = recv_list.length
        return if l == 0
        # we must look for ready consumer until success
        while true
          to = rand l
          if(recv_list[to].enq job)
            return true
          else
            #puts "WARNING: #{self}: consumer #{@cust_list[to]} is busy, looking for enother one..."
            #sleep 0.5
          end
        end
      end
    else
      return false
    end
  end
  
  # is node ready to receive a new job
  def ready?
    return @jobs.length < 1
  end

  def add_rcv(rlist)
    @cust_list += rlist
  end

  def add_nrcv(rlist)
    @ncust_list += rlist
  end

  def start()
    @thread = Thread.new{
      #while true
      begin
        payload
      rescue => e
        print_error e
      end
      #end
    }    
  end

  def stop()
    @thread.terminate
  end

  def self.opname()
    nil
  end

  def self.descr()
    nil
  end
end

class Source < Node
  #remove_method :do_job
  
  def spawn
    #sleep 0.5
    res = $example_addr
    return res
  end
  
  # true if no more jobs can be generated
  # means end of job stream
  def done?
    return false
  end
  
  def payload
    while not done?
      job = spawn
      #break if job.nil?
      pass job, true
      break if job.is_a? EndOfJobStream
    end
    #puts "------------- source #{self} finished"
  end
end

class Filter < Node
  def payload
    while true
      job = @jobs.pop
      next if job.nil?
      res = false
      if job.is_a? Job
        res = do_job job
      else
        puts "eojs"
      end
      if @invert
        res = (not res)
      end 
      #p res
      pass job, res
      break if job.is_a? EndOfJobStream
    end
    #puts "------------- filter #{self} finished"
  end
  
  def do_job(job)
    # stub
    return true if job
    return false
  end
end

class Transformer < Node
  def payload
    while true
      job = @jobs.pop
      next if not job
      if job.is_a? Job
        job = do_job job
      end
      pass(job, (not job.nil?))
      break if job.is_a? EndOfJobStream
    end
  end
  
  def do_job(job)
    return job
  end
end

#https://forum.intern0t.org/java-ruby/4158-ruby-simple-port-scanner.html
# thanks to kamrad metasplotto !
require 'socket'
def port_open?(host,port)
  begin
    aSock = Socket.new :INET, :STREAM        #build the socket
    raw = Socket.sockaddr_in port, host    
    if aSock.connect raw                     #if the socket connects...
      return true
    end
  rescue
  ensure
    aSock.close
  end
  return false
end

def shrink_text(text)
  text = text.gsub '\n', ' '
  text = text.gsub '\t', ' '
  text = text.squeeze ' '
  return text
end

def file_lines(path)
  return nil if path.nil? or not File.exists? path
  file = File.new(path, "rt")
  res = []
  while line = file.gets
    line.chomp!
    if line.empty?
      next
    end
    #line = shrink_text line
    res.push line
  end
  file.close
  return res
end

def rndbyte()
  rand 255
end

def mk_rnd_ip()
  while true
    first = rndbyte
    if (first != 10)# and (first != 127)
      return first.to_s + '.' + rndbyte.to_s + '.' + rndbyte.to_s + '.' + rndbyte.to_s
    end
  end
end

# HOW TO MAKE IT WORK IN DEBIAN
#  - install ruby-dev
#  - download and install rubygem
#  - gem install net-ping
require 'net/ping'
def online?(host)
  res = Net::Ping::External.new.ping(host)
  #puts "host up #{host}" if res
  return res
end
