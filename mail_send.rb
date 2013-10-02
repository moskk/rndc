#!/usr/bin/env ruby
require 'mail'
require 'date'
def send_mail addr_from, addr_to, message
  Mail.deliver do
     from     addr_from
     to       addr_to
     subject  "#{DateTime.now.to_date.to_s} pizza delivery!"
     body     message
     #add_file '/full/path/to/somefile.png'
  end
end


send_mail 'rndc mail bot <rndcmailbot@yandex.ru>', 'rndcmailbot@yandex.ru', 'one more test !!'