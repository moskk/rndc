#! /usr/bin/ruby

$example_addr = '93.158.134.203'
$example_addr = '66.71.253.245'

require 'ostruct'
class Job < OpenStruct
end

require 'thread'
class Node
  attr_accessor :invert
  attr_reader :thread
  attr_reader :cust_list
  @jobs = nil
  @cust_list = []
  # mode: true - result sent to all customers, false - result sent to any customer
  @mode = true
  @thread = nil
  @invert = false
  def initialize(cust_list, mode, param = nil)
    @jobs = Queue.new
    @cust_list = cust_list
    @mode = mode
    @invert = false
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
    "payload is not implemented for #{self}"
  end
  
  # passing the successfully processed job to customer(s)
  def pass(job)
    if(@mode)
      @cust_list.each{|cust|cust.enq job}
    else
      l = @cust_list.length
      #puts "recv_list len: #{l}"
      return if l == 0
      # we must look for ready consumer until success
      while true
        to = rand l
        #puts "job would sent to #{to}"
        if(@cust_list[to].enq job)
          #puts "#{self}: job #{job} sent to consumer #{@cust_list[to]}"
          return
        else
          puts "WARNING: #{self}: consumer #{@cust_list[to]} is busy, looking for enother one..."
          sleep 1
        end
      end
    end
  end
  
  # is node ready to receive a new job
  def ready?
    return @jobs.length < 1
  end

  def add_rcv(rlist)
    @cust_list += rlist
  end

  def start()
    @thread = Thread.new{
      while true
        begin
          payload
        rescue => e
          puts "payload: some shit happened in #{self}: #{e.message}\n"
          e.backtrace.each{|line| puts "\t#{line}"}
        end
      end
    }    
  end

  def stop()
    @thread.stop
    @thread.kill
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
    sleep 0.5
    res = $example_addr
    return res
  end
  
  def payload
    while true
      job = spawn
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
      if @invert
        res = (not res)
      end 
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
    return job
  end
end

def rndbyte()
  rand 255
end

def mk_rnd_ip()
  while true
    first = rndbyte
    if (first != 10) and (first != 127)
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
#     sleep 1
#     $example_addr
  end

  def self.opname()
    'rndup'
  end

  def self.descr()
    "generates some random IP address that is online now"
  end
end

class PrintFlt < Filter
  def initialize(cust_list, mode, text)
    @msg = text
    super cust_list, mode
  end
  
  def do_job(job)
    puts "#{@msg}#{job.ip}"
    return true
  end

  def self.opname()
    'printip'
  end
  
  def self.descr()
    "just prints job IP and pass the job"
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

class PortCheckFlt < Filter
  @port_list = []
  def initialize(cust_list, mode, port_list)
    @port_list = port_list
    super cust_list, mode
  end
  
  def do_job(job)
    #puts "scan #{job}"
    @port_list.each do |port|
      if not port_open? job.ip, port
        #puts "#{job}:#{port} closed"
        return false
      end
      #puts "#{job}:#{port} opened"
    end
    return true
  end

  def self.opname()
    'oport'
  end

  def self.descr()
    "check given IP on opened port(s), pass the job if all ports are opened. parameter - list of port numbers"
  end
end

require 'nokogiri'
require 'net/http'

def shrink_text(text)
  text = text.gsub '\n', ' '
  text = text.gsub '\t', ' '
  text = text.squeeze ' '
  return text
end

def grab_page(ip)
  html = nil
  begin
    uri = URI("http://#{ip}/")
    res = Net::HTTP.get_response(uri)
    #return nil if not res.response_body_permitted?
    html = res.body
  rescue
    return nil
  end
  doc = Nokogiri::HTML(html)
  # text = doc.at('body').inner_text
  # title = doc.at_css("title").text
  title = doc.title
  text = ''
  begin
    text = doc.xpath("//text()").to_s
    text = shrink_text text
  rescue Exception => e
    puts "grab_page: some shit happened: #{e.message}"
  end
  return text, html, res.code.to_i, title
end

# IP => PageInfo
require 'timeout'
class PageGraber < Transformer
  def do_job(job)
    text, html, code, title, succ = nil
    begin
      succ = Timeout::timeout(5) {
        text, html, code, title = grab_page job.ip
      }
    rescue Timeout::Error
    end
    puts "#{job.ip}: page grabing timed out" if not succ
    return nil if code.nil? or not succ
    #puts ">>>>>>> grabbed page from >#{job}<, title >#{title}<, resp_code #{code}"
    #puts "#{text}\n\n\n"
    #puts "#{html}\n\n\n"
    job.resp_code = code
    job.html = html
    job.text = text
    job.title = title
    return job
  end

  def self.opname()
    'getpage'
  end
  def self.descr()
    "download page, save its HTML code, text, title, server's responce code. mandatory transformer that must be called before calling other nodes that use mentioned job properties"
  end
end

# IP => *open in opera* => IP
class OperaOpener < Filter
  def do_job(job)
    system "opera -backgroundtab #{job.ip}"
    #puts "text len: #{job.text.length} code len: #{job.html.length}"
    return true
  end

  def self.opname()
    'oopera'
  end
  def self.descr()
    "just sends IP to Opera web-browser and pass the job"
  end
end

def file_lines(path)
  file = File.new(path, "rt")
  res = []
  while line = file.gets
    line.chomp!
    if line.empty?
      next
    end
    line = shrink_text line
    res.push line
  end
  file.close
  return res
end

# PageInfo => *page text filtering* => PageInfo
class TextFilter < Filter
  def initialize(cust_list, mode, denied_lines_file)
    @dlines = file_lines denied_lines_file
    super cust_list, mode
  end
  
  def do_job(job)
    return false if not job.text
    begin    
      @dlines.each do |dline|
	if job.text.index dline
	  puts "#{job.ip} matched: text contains #{dline}"
	  return false
	end
      end
    rescue
    end
    return true
  end

  def self.opname()
    'textf'
  end
  def self.descr()
    "check page TEXT for some strings matching. suppress the job if any matches found. parameter - list of strings file path"
  end
end

# PageInfo => *page code text filtering* => PageInfo
class PageCodeTextFilter < Filter
  def initialize(cust_list, mode, denied_lines_file)
    @dlines = file_lines denied_lines_file
    super cust_list, mode
  end
  
  def do_job(job)
    return false if not job.html
    return false if job.html.empty?
    begin
      code = shrink_text job.html
      @dlines.each do |dline|
	if code.index dline
	  puts "#{job.ip} blamed: page code contains #{dline}"
	  return false
	end
      end
    rescue
    end
    return true
  end

  def self.opname()
    'codef'
  end
  def self.descr()
    "check page CODE for some strings matching. suppress the job if any matches found.  parameter - list of strings file path"
  end
end

# PageInfo => *allowed HTTP response code* => PageInfo
class RespCodeFlt < Filter
  def initialize(cust_list, mode, allowed_codes)
    @codes = allowed_codes
    super cust_list, mode
  end
  
  def do_job(job)
    return @codes.include? job.resp_code
  end

  def self.opname()
    'respcf'
  end
  def self.descr()
    "check HTTP-server responce code for matching some values. parameter - list of allowed codes"
  end
end

# PageInfo => *allowed page title* => PageInfo
class PageTitleFlt < Filter
  def initialize(cust_list, mode, denied_titles_file)
    @titles = file_lines denied_titles_file
    super cust_list, mode
  end
  
  def do_job(job)
    title = job.title
    return true if title == nil or title.empty?
    @titles.each do |title|
      return false if title.index(title) != nil
    end
    return true
  end

  def self.opname()
    'titlef'
  end
  def self.descr()
    "check page TITLE for some strings matching. suppress the job if any matches found.  parameter - list of strings file path"
  end
end

# PageInfo => *allowed page title* => PageInfo
class IpFileSaverFlt < Filter
  def initialize(cust_list, mode, file)
    @file = file
    super cust_list, mode
  end
  
  def do_job(job)
    system "echo '#{job.ip}' >> #{@file}"
    #puts "wrote to file: #{job.ip}"
    return true
  end

  def self.opname()
    'saveip'
  end
  def self.descr()
    "saves job's IP as text into file. parameter - output file name"
  end
end

# PageInfo => *check job for condition* => PageInfo
class ConditionalFlt < Filter
  def initialize(cust_list, mode, cond)
    @cond = "job#{cond}"
    super cust_list, mode
  end
  
  def do_job(job)
    val = eval @cond
    puts "#{self}:   #{@cond} => #{val}"
    return val
  end

  def self.opname()
    'condf'
  end
  def self.descr()
    "check the job for some condition given as Ruby string"
  end
end

# PageInfo => *check job for domain name* => PageInfo
require 'resolv'
class ReverseDnsFlt < Filter
  def initialize(cust_list, mode, param)
    super cust_list, mode
  end
  
  def do_job(job)
    name = nil
    begin
      name = Resolv.getname job.ip
    rescue
      return false
    end
    return true
  end

  def self.opname()
    'rdnsf'
  end
  def self.descr()
    "gathers a job's domain name by IP, suppress unnamed jobs"
  end
end

