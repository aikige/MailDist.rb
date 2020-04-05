#!/usr/bin/env ruby

#require 'mail'
require 'mail-iso-2022-jp'

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
	mail = Mail.new(:charset => CHARSET)
	mail.from(FROM_ADDRESS)
	mail.to(@to)
	mail.subject(@subject)
	mail.body(@body)
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
