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
  def initialize(cust_list, mode, params = nil)
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
          #puts "WARNING: #{self}: consumer #{@cust_list[to]} is busy, looking for enother one..."
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

class PrintFlt < Filter
  def initialize(cust_list, mode, params)
    @msg = params[0]
    super cust_list, mode
  end
  
  def do_job(job)
    puts "#{@msg}#{job.url}"
    return true
  end

  def self.opname()
    'printip'
  end
  
  def self.descr()
    "just prints job URL and pass the job. parameter - message string printed before IP"
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
  def initialize(cust_list, mode, params)
    @port_list = params[0]
    super cust_list, mode
  end
  
  def do_job(job)
    #puts "scan #{job}"
    @port_list.each do |port|
      if not port_open?(job.ip, port)
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

def shrink_text(text)
  text = text.gsub '\n', ' '
  text = text.gsub '\t', ' '
  text = text.squeeze ' '
  return text
end

require 'nokogiri'
require 'net/http'
def grab_page(url)
  html = nil
  begin
    uri = URI("http://#{url}/")
    res = Net::HTTP.get_response(uri)
    #return nil if not res.response_body_permitted?
    html = res.body
  rescue Exception => e
    puts "exc: #{e.message}"
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
  #puts  [text, html, res.code.to_i, title]
  return text, html, res.code.to_i, title
end

# IP => PageInfo
require 'timeout'
class PageGraber < Transformer
  # page graber can use job's domain name field (if it is presented)
  # for page querying. if some job have multiple names then 
  # every name will be ascked for page and every response will spawn
  # a new job. so we have to redefine payload
  def payload
    while true
      job = @jobs.pop
      next if not job
      if not job.domain.nil?
        job.domain.each do |d|
          subjob = job.clone
          subjob.domain = [d]
          subjob = do_job subjob
          next if not subjob
          pass subjob
        end
      elsif not job.ip.empty?
        job.delete_field 'domain' if not job.domain.nil?
        job = do_job job
        next if not job
        pass job
      end
    end
  end
  
  def do_job(job)
    text, html, code, title, succ = nil
    begin
      #puts "#{job.url}: page grabing startsed" if not succ
      succ = Timeout::timeout(5) {
        text, html, code, title = grab_page job.url
      }
    rescue Timeout::Error
      puts "#{job.url}: page grabing timed out"
      return nil
    end
    if succ.nil?
      puts "#{job.url}: page grabing failed"
      return nil
    end
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

# IP => *open url in opera* => IP
class OperaOpener < Filter
  def do_job(job)
    url = job.domain.nil?? job.ip : job.domain[0]
    system "opera -backgroundtab #{url}"
    #puts "text len: #{job.text.length} code len: #{job.html.length}"
    return true
  end

  def self.opname()
    'oopera'
  end
  def self.descr()
    "just sends IP to Opera web browser and pass the job"
  end
end

# IP => *open url in iceweasel* => IP
class IceweaselOpener < Filter
  def do_job(job)
    url = job.domain.nil?? job.ip : job.domain[0]
    system "iceweasel -new-tab #{url} &"
    #puts "text len: #{job.text.length} code len: #{job.html.length}"
    return true
  end

  def self.opname()
    'oicew'
  end
  def self.descr()
    "just sends IP to Iceweasel web browser and pass the job"
  end
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

# PageInfo => *page text filtering* => PageInfo
class TextFilter < Filter
  def initialize(cust_list, mode, params)
    @dlines = file_lines params[0]
    super cust_list, mode
  end
  
  def do_job(job)
    return false if not job.text
    begin    
      @dlines.each do |dline|
        if job.text.index dline
          puts "#{job.url} matched: text contains #{dline}"
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
  def initialize(cust_list, mode, params)
    @dlines = file_lines params[0]
    super cust_list, mode
  end
  
  def do_job(job)
    return false if not job.html
    return false if job.html.empty?
    begin
      code = shrink_text job.html
      @dlines.each do |dline|
	if code.index dline
	  puts "#{job.url} matched: page code contains #{dline}"
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
  def initialize(cust_list, mode, params)
    @codes = params[0]
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
  def initialize(cust_list, mode, params)
    @titles = file_lines params[0]
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
  def initialize(cust_list, mode, params)
    @file = params[0]
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
  def initialize(cust_list, mode, params)
    @cond = "job#{params[0]}"
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
  def initialize(cust_list, mode, params)
    if not params[0].nil?
      @levels = param[:levels]
      @allowed = file_lines param[:allowed]
      @denied = file_lines param[:denied]
    end
    super cust_list, mode
  end
  
  def do_job(job)
    names = nil
    begin
      names = Resolv.getnames job.ip
    rescue
      return false
    end
    
    return false if names.empty?
    
    job.domain = names
    
    names.each do |name|
      return false if not filter name
    end
    
    return true
  end
  
  def filter(name)
    if not @levels.nil?
      lvls = name.split('.').count
      val = eval(lvls.to_s + @levels)
      if not val
        return false
      end
    end
    
    if not @denied.nil?
      @denied.each do |line|
        if not name[line].nil?
          return false
        end
      end
    end
    
    if not @allowed.nil?
      @allowed.each do |line|
        if not name[line].nil?
          return true
        end
      end
    end
    return true
  end

  def self.opname()
    'rdnsf'
  end
  def self.descr()
    "gathers a job's domain names by IP, suppress unnamed jobs"
  end
end

class Delayer < Transformer
  def initialize(cust_list, mode, params)
  @delay = params[0]
  #puts "DELAY _ _ _ _ _ _ #{delay}"
  @urllist = []
  super cust_list, mode
  @result = nil
  @timer = Thread.new {
    while true
      print '.'
      sleep @delay
      if not @urllist.empty?
        #p @urllist
        if @result.nil?
          @result = Job.new
          @result.log = ''
        end
        1.upto @urllist.length do
          @result.log << @urllist.shift << "\n"
        end
        #puts "ACCUM #{@result.log}"
      end
    end
  }
  end
  
  def do_job(job)
    @urllist << job.url if not job.url.nil?
    #puts "got job, urllist now is #{@urllist}"
    if not @result.nil?
      res = @result.clone
      @result = nil
      @urllist = []
      return res
    end
    return nil
  end
  
  def self.opname()
    'accumf'
  end
  
  def self.descr()
    "accumulate job's urls as string list and delay it for specified period"
  end
end

class DebugSource < Source
  def spawn
    sleep 3
    job = Job.new
    job.ip = '66.49.130.149'
    #p job
    return job
  end
  
  def self.opname()
    'ds'
  end
  
  def self.descr()
    "debug source. once a second generates a job with some special ip"
  end
end

require 'mail'
require 'date'
def send_mail(addr_from, addr_to, topic, message)
  puts "send mail #{addr_from} #{addr_to} #{message} "
  Mail.deliver do
    from     addr_from
    to       addr_to
    #subject  "#{DateTime.now.to_date.to_s} pizza delivery!"
    subject  "#{topic}"
    body     message
    #add_file '/full/path/to/somefile.png'
  end
end

# takes job's text field and send it to email list
class MailerFlt < Filter
  def initialize(cust_list, mode, params)
    # params: [tolist, from, topic]
    #puts "->>>>>>>>>>>>>>>>>>>>>>>>>>>>>> #{email_list_file}"
    @emails_file = params[0]
    @from = params[1]
    @topic = params.fetch(2, self)
    super cust_list, mode
  end
  
  def do_job(job)
    emails = file_lines @emails_file
    p emails
    if not job.log.nil?
      emails.each do |email|
        #if not email.nil? and send_mail('rndc mail bot <rndcmailbot@yandex.ru>', email, job.log)
        p [@from, email, @topic, job.log]
        if not email.nil? and send_mail(@from, email, @topic, job.log)
          puts "email sent to #{email}: " 
        else
          puts "faillll" 
        end
      end
    end
  end
  
  def self.opname()
    'mailf'
  end
  
  def self.descr()
    "send email with job's text field as message. parameter - file-list of email addresses"
  end
end

