
$FS = '[:||||:]'
class LogFilter < Filter
  def initialize(cust_list, ncust_list, mode, params)
    if not $logging
      puts "WARNING: logging disabled but logger nodes used in script, they will not work"
      puts "WARNING: to enable it use -l command line key"
    end
    @logfile = params[0]
    super cust_list, ncust_list, mode
  end
  
  def do_job(job)
    if not $logging or not job.is_a? Job
      return true
    end
    loglines = job.url.clone
    sn = "\n"
    loglines << sn << job.log.join(sn) << sn << $FS << sn
    write_file @logfile, loglines
    return true
  end

  def self.opname()
    ['logf','Logger']
  end
  
  def self.descr()
    "write lines of job's log in specified file"
  end
  
  def log_info()
    []
  end
  
end

register_node_class LogFilter
