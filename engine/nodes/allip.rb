
require 'ipaddr'

def first_ip_as_int()
  [1,0,0,0].pack("cccc").unpack("N")[0]
  #IPAddr.new("1.0.0.0", Socket::AF_INET).to_i
end

def split_ip(ip_as_int)
  [ip_as_int].pack("N").unpack("cccc")
end

def next_internet_addr(ip_as_int)
  ip_as_int = ip_as_int + 1
  a, b, c, d = split_ip ip_as_int
  #p [a,b,c,d]
  res = true
  if a == 127 || a == 10 then
    a += 1
    #p 1, [a,b,c,d]
  elsif a == 192 and b == 168 then
    b += 1
    #p 2, [a,b,c,d]
  elsif a == 172 and (16..31).include? b then
    b += 1
    #p 3, [a,b,c,d]
  elsif a == 169 and b == 254 then
    b += 1
    #p 4, [a,b,c,d]
  elsif a == 224 then
    return 0, false
    #p 5, [a,b,c,d]
  else
    return ip_as_int, true
  end
  [[a,b,c,d].pack("cccc").unpack("N"), true]
end

=begin
1.upto 100000 do|addr|
  addr, ok = next_internet_addr(addr)
  p IPAddr.new(addr,Socket::AF_INET).to_s
end
exit 0
=end

class AllIpSrc < Source
  def initialize(cust_list, ncust_list, mode, params)
    #p cust_list, ncust_list, mode, params
    @addr = first_ip_as_int
    super cust_list, ncust_list, mode
  end
  
  def spawn
    @addr, ok = next_internet_addr @addr
    if ok then
      job = Job.new
      ip = IPAddr.new(@addr,Socket::AF_INET).to_s
      #puts "-- #{ip}"
      job.ip = ip
      Thread.pass
      return job
    else
      return EndOfJobStream.new
    end
  end

  def self.opname()
    ['allip', 'AllIp']
  end

  def self.descr()
    "generates sequential stream of all sensible internet addresses"
  end
  
  def log_info()
    "next IP"
  end
end

register_node_class AllIpSrc

