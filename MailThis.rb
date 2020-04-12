#!/usr/bin/env ruby

require 'mail'

begin
  require_relative('config')
rescue LoadError
  puts <<EOS
Plese create "config.rb", which contains following constants.

SMTP_SERVER_ADDRESS = 'smtp.gmail.com'
SMTP_SERVER_PORT = 587
SMTP_ENABLE_TLS = true
SMTP_USER_NAME = 'sample@gmal.com'
SMTP_PASS = 'xxxxxxxxxxxxxx'
FROM_ADDRESS = SMTP_USER_NAME
CHARSET = 'ISO-2022-JP'
EOS
  exit
end

class MailThis
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
		when /^cc:/i then
		  @cc = l.sub(/^cc:\s+/i, '')
		end
	  end
	  @body = f.read
	}
    @attachments = Array.new
  end

  def add_attachment(file)
    @attachments.push(file)
  end

  def send
    # Common part.
    @mail = Mail.new
    @mail.charset = CHARSET
    @mail.to = @to unless @to.nil?
    @mail.cc = @cc unless @cc.nil?
    @mail.from = FROM_ADDRESS
    @mail.subject = @subject unless @subject.nil?
    @mail.charset = CHARSET
    if (CHARSET.upcase == 'ISO-2022-JP')
      # Special handling for ISO-2022-JP encoding.
      @mail.content_transfer_encoding = '7bit'
    end
    # Add format dependent body.
    if (@html == true)
      encode_text_part(remove_html_tag(@body))
      encode_html_part(@body)
    elsif (@attachments.size > 0)
      encode_text_part(@body)
    else
	  @mail.body = @body
    end
    # Add attachments.
    @attachments.each do |f|
      encode_attachment(f)
    end

	opt = {
	  :address => SMTP_SERVER_ADDRESS,
	  :port => SMTP_SERVER_PORT,
	  :authentication => :login,
	  :enable_starttls_auto => true,
	  :user_name => SMTP_USER_NAME,
	  :password => SMTP_PASS,
	}
	@mail.delivery_method(:smtp, opt)

    debug = true
    unless debug
	  mail.deliver!
    else
	  puts @mail.to_s
    end
  end

  def to_s
	"body=#{@body},subject=#{@subject},to=#{@to}"
  end

  private

  def remove_html_tag(str)
    str.gsub(%r{</?[^>]+?>}, '')
  end

  def encode_text_part(body)
    text_part = Mail::Part.new
    text_part.content_type = "text/plain;charset=#{CHARSET}"
    if (CHARSET.upcase == 'ISO-2022-JP')
      # Special handling for ISO-2022-JP encoding.
      text_part.content_transfer_encoding = '7bit'
    end
    text_part.body = body
    @mail.text_part = text_part
  end

  def encode_html_part(body)
    html_part = Mail::Part.new
    html_part.content_type = "text/html;charset=UTF-8"
    html_part.body = body
    @mail.html_part = html_part
  end

  def encode_attachment(file)
    @mail.add_file(file)
  end
end

if $0 == __FILE__
  m = MailThis.new(ARGV.shift)
  while f = ARGV.shift do
    m.add_attachment(f)
  end
  p m.to_s
  m.send
end
