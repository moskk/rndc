

# PageInfo => *check job for domain name* => PageInfo
require 'resolv'
class ReverseDnsFlt < Filter
  def initialize(cust_list, ncust_list, mode, params)
    if not params[0].nil?
      @levels = param[:levels]
      @allowed = file_lines param[:allowed]
      @denied = file_lines param[:denied]
    end
    super cust_list, ncust_list, mode
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

register_node_class ReverseDnsFlt

