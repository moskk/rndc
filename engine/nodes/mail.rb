
require 'mail'
require 'date'
def send_mail(addr_from, addr_to, topic, message)
  puts "send mail #{addr_from} #{addr_to} #{message} "
  Mail.deliver do
    from     addr_from
    to       addr_to
    #subject  "#{DateTime.now.to_date.to_s} pizza delivery!"
    subject  "#{topic}"
    body     message
    #add_file '/full/path/to/somefile.png'
  end
end

# takes job's text field and send it to email list
class MailerFlt < Filter
  def initialize(cust_list, ncust_list, mode, params)
    # params: [tolist, from, topic]
    #puts "->>>>>>>>>>>>>>>>>>>>>>>>>>>>>> #{email_list_file}"
    @emails_file = params[0]
    @from = params[1]
    @topic = params.fetch(2, self)
    super cust_list, ncust_list, mode
  end
  
  def do_job(job)
    emails = file_lines @emails_file
    p emails
    if not job.log.nil?
      emails.each do |email|
        #if not email.nil? and send_mail('rndc mail bot <rndcmailbot@yandex.ru>', email, job.log)
        p [@from, email, @topic, job.log]
        if not email.nil? and send_mail(@from, email, @topic, job.log)
          puts "email sent to #{email}: " 
        else
          puts "faillll" 
        end
      end
    end
  end
  
  def self.opname()
    'mailf'
  end
  
  def self.descr()
    "send email with job's text field as message. parameter - file-list of email addresses"
  end
end

register_node_class MailerFlt

