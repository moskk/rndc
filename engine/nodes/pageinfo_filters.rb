
# PageInfo => *page text filtering* => PageInfo
class TextFilter < Filter
  def initialize(cust_list, ncust_list, mode, params)
    @dlines = file_lines params[0]
    super cust_list, ncust_list, mode
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
    ['textf','FilterByPageText']
  end
  def self.descr()
    "check page TEXT for some strings matching. suppress the job if any matches found. parameter - list of strings file path"
  end
end

# PageInfo => *page code text filtering* => PageInfo
class PageCodeTextFilter < Filter
  def initialize(cust_list, ncust_list, mode, params)
    @dlines = file_lines params[0]
    super cust_list, ncust_list, mode
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
    ['codef','FilterByPageCode']
  end
  def self.descr()
    "check page CODE for some strings matching. suppress the job if any matches found.  parameter - list of strings file path"
  end
end

# PageInfo => *allowed HTTP response code* => PageInfo
class RespCodeFlt < Filter
  def initialize(cust_list, ncust_list, mode, params)
    @codes = params[0]
    super cust_list, ncust_list, mode
  end
  
  def do_job(job)
    return @codes.include? job.resp_code
  end

  def self.opname()
    ['respcf','FilterByHttpCode']
  end
  def self.descr()
    "check HTTP-server responce code for matching some values. parameter - list of allowed codes"
  end
end

# PageInfo => *allowed page title* => PageInfo
class PageTitleFlt < Filter
  def initialize(cust_list, ncust_list, mode, params)
    @titles = file_lines params[0]
    super cust_list, ncust_list, mode
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
    ['titlef','FilterByPageTitle']
  end
  def self.descr()
    "check page TITLE for some strings matching. suppress the job if any matches found. parameter - list of strings file path"
  end
end

# PageInfo => *check job for condition* => PageInfo
class ConditionalFlt < Filter
  def initialize(cust_list, ncust_list, mode, params)
    @cond = "job#{params[0]}"
    super cust_list, ncust_list, mode
  end
  
  def do_job(job)
    val = eval @cond
    puts "#{self}:   #{@cond} => #{val}"
    return val
  end

  def self.opname()
    ['condf', 'FilterByJobCondition']
  end
  def self.descr()
    "check the job for some condition given as Ruby string"
  end
end

register_node_class TextFilter
register_node_class PageCodeTextFilter
register_node_class RespCodeFlt
register_node_class PageTitleFlt
register_node_class ConditionalFlt
