

class PingFlt < Filter
  def initialize(cust_list, ncust_list, mode, params)
    super cust_list, ncust_list, mode
  end
  
  def do_job(job)
    return true
  end

  def self.opname()
    ['pingf', 'PingIp']
  end
  
  def self.descr()
    "ping job's IP, forward responded IPs"
  end
  
  def log_info()
    'send ping rq to host and wait for responce'
  end
end

register_node_class PingFlt

