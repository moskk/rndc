
class PrintFlt < Filter
  def initialize(cust_list, ncust_list, mode, params)
    @msg = params.fetch(0,'')
    super cust_list, ncust_list, mode
  end
  
  def do_job(job)
    puts "#{@msg}#{job.url}"
    return true
  end

  def self.opname()
    ['printip','PrintUrl']
  end
  
  def self.descr()
    "just prints job URL and pass the job. parameter - message string printed before IP"
  end
  
  def log_info()
    "#{@msg} printed"
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
    ['oopera','BrowseOpera']
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
    ['oicew','BrowseIceweasel']
  end
  def self.descr()
    "just sends IP to Iceweasel web browser and pass the job"
  end
end

# PageInfo => *allowed page title* => PageInfo
class IpFileSaverFlt < Filter
  def initialize(cust_list, ncust_list, mode, params)
    @file = params[0]
    super cust_list, ncust_list, mode
  end
  
  def do_job(job)
    #system "echo '#{job.ip}' >> #{@file}"
    write_file @file, job.ip
    #puts "wrote to file: #{job.ip}"
    return true
  end

  def self.opname()
    ['saveip','SaveUrl']
  end
  def self.descr()
    "saves job's IP as text into file. parameter - output file name"
  end
end

register_node_class PrintFlt
register_node_class OperaOpener
register_node_class IceweaselOpener
register_node_class IpFileSaverFlt
