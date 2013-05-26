#! /usr/bin/ruby

$example_addr = '93.158.134.203'
$example_addr = '66.71.253.245'

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
      #sleep 5
      begin
        payload
      rescue => e
	puts "payload: some shit happened in #{self}: #{e.message}\n"
	e.backtrace.each{|line| puts "\t#{line}"}
      end
    }
  end
  
  def enq(job, from = nil)
    @jobs.enq job
  end
  
  def payload
    "payload is not implemented for #{self}"
  end
  
  def pass(job)
    if(@mode)
      @cust_list.each{|cust|cust.enq job}
    else
      l = @cust_list.length
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
  return res
end

class HostsUpSrc < Source
  def summoun
    while true
      addr = mk_rnd_ip
      return addr if online? addr
    end
#     sleep 1
#     $example_addr
  end
end

class PrintFlt < Filter
  def initialize(cust_list, text = '', mode = true)
    @msg = text
    super cust_list, mode
  end
  
  def do_job(job)
    puts "#{@msg}#{job}"
    return true
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
  def initialize(cust_list, port_list, mode = true)
    @port_list = port_list
    super cust_list, mode
  end
  
  def do_job(job)
    sock = nil
    @port_list.each do |port|
      if not port_open? job, port
	return false
      end
      next
    end
    return true
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
    html = res.body
  rescue
    return nil
  end
  doc = Nokogiri::HTML(html)
  text = doc.xpath("//text()").to_s
  # text = doc.at('body').inner_text
  # title = doc.at_css("title").text
  title = doc.title
  return (shrink_text text), html, res.code.to_i, title
end

# IP => PageInfo
class PageInfo
  attr_accessor :text
  attr_accessor :ip
  attr_accessor :resp_code
  attr_accessor :html
  attr_accessor :title
  def initialize(ip, code, html, text, title)
    @text = text
    @ip = ip
    @resp_code = code
    @html = html
    @title = title
  end
end

class PageGraber < Transformer
  def do_job(job)
    text, html, code, title = grab_page job
    return PageInfo.new job, code, html, text, title
  end
end

# IP => *opne in opera* => IP
class OperaOpener < Filter
  def do_job(job)
    system "opera -backgroundtab #{job.ip}"
    return true
  end
end

def file_lines(path)
  file = File.new(path, "rt")
  res = []
  while line = file.gets
    line.chop!
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
class TextDenier < Filter
  def initialize(cust_list, denied_lines_file, mode = true)
    @dlines = file_lines denied_lines_file
    super cust_list, mode
  end
  
  def do_job(job)
    return false if not job.text
    begin    
      @dlines.each do |dline|
	if job.text.index dline
	  puts "#{job} text contains #{dline}"
	  return false
	end
      end
    rescue
    end
    return true
  end
end

# PageInfo => *page code text filtering* => PageInfo
class PageCodeTextDenier < Filter
  def initialize(cust_list, denied_lines_file, mode = true)
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
	  puts "#{job.ip} text contains #{dline}"
	  return false
	end
      end
    rescue
    end
    return true
  end
end

# PageInfo => *allowed HTTP response code* => PageInfo
class RespCodeFlt < Filter
  def initialize(cust_list, allowed_codes, mode = true)
    @codes = allowed_codes
    super cust_list, mode
  end
  
  def do_job(job)
    return @codes.include? job.resp_code
  end
end

# PageInfo => *allowed page title* => PageInfo
class PageTitleFlt < Filter
  def initialize(cust_list, denied_titles_file, mode = true)
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
end

# PageInfo => *allowed page title* => PageInfo
class IpFileSaverFlt < Filter
  def initialize(cust_list, file, mode = true)
    @file = file
    super cust_list, mode
  end
  
  def do_job(job)
    system "echo '#{job.ip}' >> #{@file}"
    puts "wrote to file: #{job.ip}"
    return true
  end
end

##########################################
#        E N T R Y   P O I N T
##########################################

# oo = OperaOpener.new []

fsflt = IpFileSaverFlt.new [], './result.list'


tctd = PageCodeTextDenier.new [fsflt], './denied.words'


ptflt = PageTitleFlt.new [tctd], './denied.titles'


cflt = RespCodeFlt.new [ptflt], [200]


pg = PageGraber.new [cflt]
printer = PrintFlt.new [], 'p80 ok: '

hups_list = []
1.upto 50 do
  hups_list.push PortCheckFlt.new [printer, pg], [80]
end


1.upto 200 do
  HostsUpSrc.new hups_list, false
end

puts '-------------S T A R T E D----------------'

gets 
