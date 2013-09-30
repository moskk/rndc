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
          subjob = nil
          begin
            subjob = job.clone
            subjob.domain = [d]
            subjob = do_job subjob
          rescue
            next
          end
          next if subjob.nil?
          pass subjob
        end
      elsif not job.ip.empty?
        job.delete_field 'domain' if not job.domain.nil?
        job = do_job job
        #next if not job
        pass(job, (not job.nil?))
      end
    end
  end
  
  def do_job(job)
    text, html, code, title, succ = nil
    begin
      #puts "#{job.url}: page grabing startsed" if not succ
      succ = Timeout::timeout(15) {
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

register_node_class PageGraber