
class Delayer < Transformer
  def initialize(cust_list, ncust_list, mode, params)
  @delay = params[0]
  #puts "DELAY _ _ _ _ _ _ #{delay}"
  @urllist = []
  super cust_list, ncust_list, mode
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
    ['ds', 'SrcDebug']
  end
  
  def self.descr()
    "debug source. once a second generates a job with some special ip"
  end
end

class FileHostsSrc < Source
  @files = []
  @addrlines = []
  @nline = 0
  @done = false
  def initialize(cust_list, ncust_list, mode, params)
    #p cust_list, ncust_list, mode, params
    @files = params
    @addrlines = []
    @files.each do |file|
      @addrlines.concat file_lines(file)
    end
    @nline = 0
    @done = false
    super cust_list, ncust_list, mode
  end
  
  def spawn
    if @nline >= @addrlines.length
      @done = true
      return EndOfJobStream.new
    else
      job = Job.new
      job.ip = @addrlines[@nline]
      @nline += 1
      #sleep 0.5
      return job
    end
  end

  def self.opname()
    'filesrc'
  end

  def self.descr()
    "reads addresses from specified text file"
  end
  
    def done?
    return @done
  end
end

register_node_class Delayer
register_node_class DebugSource
register_node_class FileHostsSrc
