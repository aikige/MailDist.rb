#!/usr/bin/env ruby

require 'mail'
require 'mime/types'
require 'base64'
require 'nkf'

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
  attr_writer :from, :password, :user_name, :to, :cc, :subject, :log

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
    @charset = CHARSET
    @from = FROM_ADDRESS
    @user_name = SMTP_USER_NAME
    @password = SMTP_PASS
    @attachments = Array.new
    @log = nil
  end

  def add_attachment(file)
    @attachments.push(file)
  end

  def send(is_new = true)
    # Common part.
    if is_new
      encode_message
    else
      if @mail.nil?
        encode_message
      else
        # Update To, Cc and From.
        @mail.to = @to unless @to.nil?
        @mail.cc = @cc unless @cc.nil?
        @mail.from = @from
        # Trick to update Message-ID field.
        @mail.add_message_id
      end
    end

	opt = {
	  :address => SMTP_SERVER_ADDRESS,
	  :port => SMTP_SERVER_PORT,
	  :authentication => :login,
	  :enable_starttls_auto => SMTP_ENABLE_TLS,
	  :user_name => @user_name,
	  :password => @password,
	}
	@mail.delivery_method(:smtp, opt)

    unless DEBUG
      show_log("Sending from #{@from.to_s} to #{@to.to_s}...")
	  mail.deliver!
      show_log('Done!')
    else
	  show_log(@mail.to_s)
    end
  end

  def to_s
	"body=#{@body},subject=#{@subject},to=#{@to}"
  end

  private

  def show_log(str)
    @log.puts(str) unless @log.nil?
    STDERR.puts(str)
  end

  def encode_message
    # Common part.
    @mail = Mail.new
    @mail.charset = @charset
    @mail.to = @to unless @to.nil?
    @mail.cc = @cc unless @cc.nil?
    @mail.from = @from
    @mail.subject = @subject unless @subject.nil?
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
  end

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

  def encode_attachment_unused(file)
    # Note: do not use this since text encoding will not work.
    @mail.add_file(file)
  end

  def encode_attachment(file)
    body = File.binread(file)
    type = MIME::Types.type_for(file)[0].to_s
    if type =~ /text\/.*/ then
      # Note: workaround - Mail tend to add 'charset=UTF8' for
      # the text files without checking actual charset of the file.
      # So, this script puts type manually.
      # NKF gives better suggestion than String::encoding
      type += ";charset=#{NKF.guess(body).to_s}"
    end
    @mail.attachments[file] = {
      :content_type => type,
      :content_transfer_encoding => 'base64',
      :content => Base64.encode64(body),
    }
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
