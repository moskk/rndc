
class PortCheckFlt < Filter
  @port_list = []
  def initialize(cust_list, ncust_list, mode, params)
    @port_list = params[0]
    super cust_list, ncust_list, mode
  end
  
  def do_job(job)
    #puts "scan #{job}"
    @port_list.each do |port|
      if not port_open?(job.ip, port)
        @joblog << "port #{port} closed" if $logging
        return false
      end
      @joblog << "port #{port} opened" if $logging
    end
    return true
  end

  def self.opname()
    ['oport','CheckTcpPort']
  end

  def self.descr()
    "check given IP on opened port(s), pass the job if all ports are opened. parameter - list of port numbers"
  end
  
  def log_info()
    "tryed to connect on TCP ports #{@port_list}"
  end
end

register_node_class PortCheckFlt

