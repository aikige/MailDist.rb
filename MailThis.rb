#!/usr/bin/env ruby

require 'mail'

begin
  require_relative('config')
rescue LoadError
  SMTP_SERVER_ADDRESS = 'smtp.gmail.com'
  SMTP_SERVER_PORT = 587
  SMTP_DOMAIN = 'gmail.com'
  SMTP_ENABLE_TLS = true
  SMTP_USER_NAME = 'sample@gmal.com'
  SMTP_PASS = 'xxxxxxxxxxxxxx'
  FROM_ADDRESS = SMTP_USER_NAME
  CHARSET = 'ISO-2022-JP'
end

class MailObject
  attr_reader :subject, :to, :body
  def initialize(filename)
    if (filename =~ /.html*$/)
      @html = true
    else
      @html = false
    end
	File.open(filename) { |f|
	  loop do
		l = f.gets.chomp
		case l
		when /^$/ then
		  break
		when /^subject:/i then
		  @subject = l.sub(/^subject:\s+/i, '')
		when /^to:/i then
		  @to = l.sub(/^to:\s+/i, '')
		end
	  end
	  @body = f.read
	}
  end
  def send
    if (@html == true)
      # For HTML, always use UTF-8 as charset.
	  mail = Mail.new
      mail.charset = 'UTF-8'
      mail.to(@to)
      mail.from(FROM_ADDRESS)
      mail.subject(@subject)
      text_part = Mail::Part.new
      text_part.content_type("text/plain; charset=UTF-8")
      text_part.body(@body.gsub(%r{</?[^>]+?>}, ''))
      html_part = Mail::Part.new
      html_part.content_type("text/html; charset=UTF-8")
      html_part.body(@body)
      mail.text_part = text_part
      mail.html_part = html_part
    else
	  mail = Mail.new
      mail.charset = CHARSET
      mail.to(@to)
      mail.from(FROM_ADDRESS)
      mail.subject(@subject)
      if (CHARSET.upcase == 'ISO-2022-JP')
        mail.content_transfer_encoding = '7bit'
      end
	  mail.body(@body)
    end

	opt = {
	  :address => SMTP_SERVER_ADDRESS,
	  :port => SMTP_SERVER_PORT,
	  :domain => SMTP_DOMAIN,
	  :user_name => SMTP_USER_NAME,
	  :password => SMTP_PASS,
	  :authentication => :login,
	  :enable_starttls_auto => true
	}
	mail.delivery_method(:smtp, opt)
	mail.deliver!
	#puts mail.to_s
  end
  def to_s
	"body=#{@body},subject=#{@subject},to=#{@to}"
  end
end

m = MailObject.new(ARGV[0])
p m.to_s
m.send
