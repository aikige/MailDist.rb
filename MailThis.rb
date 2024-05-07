#!/usr/bin/env ruby

#require 'mail'
require 'mail-iso-2022-jp'
require 'mime/types'
require 'base64'
require 'nkf'
require "json"
#require "openssl"

# Add script directory and current directory in Load Path.
$LOAD_PATH.unshift(File.dirname(File.expand_path(__FILE__)))
$LOAD_PATH.unshift(Dir.pwd)

# Load configuration file.
begin
  require 'config'
rescue LoadError
end

class MailConfig
  KEYS = [
      "smtp_server_address",
      "smtp_server_port",
      "smtp_enable_tls",
      "smtp_user_name",
      "smtp_pass",
      "from_address",
      "charset",
      "list_unsubscribe_base",
      "list_unsubscribe_message",
      "validate_ssl",
      "debug"
  ]
  def initialize(filename = "config.json")
    # Default values for mandatory members.
    add_variable('from_address', nil)
    add_variable('smtp_user_name', nil)
    add_variable('smtp_pass', nil)
    # Import members.
    import_const()
    File.exist?(filename) and File.open(filename) do |j|
      import_hash(JSON.load(j))
    end
    validate()
  end

  def debug?()
    return false unless defined?(@debug)
    return @debug
  end

  private def validate()
    raise "smtp_enable_tls shall be bool" unless is_bool?(@smtp_enable_tls)
    raise "smtp_server_port shall be int" unless @smtp_server_port.is_a?(Integer)
    raise "smtp_server_address is not defined" unless defined?(@smtp_server_address)
    @charset = 'ISO-2022-JP' unless defined?(@charset)
    @smtp_pass = nil unless defined?(@smtp_pass)
    @smtp_user_name = nil unless defined?(@smtp_user_name)
    @from_address = nil unless defined?(@from_address)
    @validate_ssl = true unless defined?(@validate_ssl)
    unless defined?(@list_unsubscribe_message)
      @list_unsubscribe_message = "Link to unsubscribe " 
    end
  end

  private def import_hash(hash)
    return unless hash.is_a?(Hash)
    KEYS.each do |key|
      add_variable(key, hash[key]) if hash.has_key?(key)
    end
  end

  private def import_const()
    KEYS.each do |key|
      add_variable(key, eval("#{key.upcase}")) if eval("defined?(#{key.upcase})")
    end
  end

  private def is_bool?(val)
    return !!val == val
  end

  private def add_variable(name, value)
    instance_variable_set("@#{name}", value)
    self.class.send(:attr_reader, name) unless respond_to?(name)
  end
end

class MailThis
  attr_writer :from, :password, :user_name, :to, :cc, :subject, :log, :name, :list_unsubscribe_unique

  def initialize(filename, config_fn = 'config.json')
    @config = MailConfig.new(config_fn)
    if (filename =~ /.html*$/)
      @html = true
    else
      @html = false
    end
    @list_unsubscribe_unique = nil
    @attachments = Array.new
    @log = nil
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
        when /^list-unsubscribe-unique:/i then
          @list_unsubscribe_unique = l.sub(/^list-unsubscribe-unique:\s+/i, '')
        end
      end
      @body = f.read
    }
    @from = @config.from_address
    @user_name = @config.smtp_user_name
    @password = @config.smtp_pass
  end

  def add_attachment(file)
    @attachments.push(file)
  end

  def send(from_scratch = true)
    # Check necessary fields.
    raise "no @from" if @from.nil?
    raise "no @to" if @to.nil?
    raise "no @subject" if @subject.nil?
    raise "no @user_name" if @user_name.nil?
    raise "no @password" if @password.nil?

    @mail = nil if from_scratch

    # Note: encode everytime, since body may includes unsubscribe link.
    encode_message

    if @config.validate_ssl
      ssl_verify_mode = nil
    else
      ssl_verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
    opt = {
      :address => @config.smtp_server_address,
      :port => @config.smtp_server_port,
      :authentication => :login,
      :enable_starttls_auto => @config.smtp_enable_tls,
      :user_name => @user_name,
      :password => @password,
      :openssl_verify_mode => ssl_verify_mode,
    }
    @mail.delivery_method(:smtp, opt)

    if @config.debug?
      show_log(@mail.to_s)
    else
      show_log("Sending from #{@from.to_s} to #{@name} <#{@to.to_s}>...")
      @mail.deliver!
      show_log('Done!')
    end
  end

  def to_s
    "body=#{@body},subject=#{@subject},to=#{@to}"
  end

  private def show_log(str)
    @log.puts(str) unless @log.nil?
    STDERR.puts(str)
  end

  private def add_list_unsubscribe(body)
    return body if @list_unsubscribe_unique.nil?
    if @config.respond_to?(:list_unsubscribe_base) then
      link = @config.list_unsubscribe_base + @list_unsubscribe_unique
    else
      link = @list_unsubscribe_unique
    end
    @mail.header['List-Unsubscribe'] = "<#{link}>"
    @mail.header['List-Unsubscribe-Post'] = 'List-Unsubscribe=One-Click'
    if (@html == true)
      body += "<a href=\"#{link}\">#{@config.list_unsubscribe_message}</a>"
    else
      body += "#{@config.list_unsubscribe_message}#{link}"
    end
    return body
  end

  private def encode_message
    # Common part.
    @mail = Mail.new
    @mail.charset = @config.charset
    @mail.to = @to unless @to.nil?
    @mail.cc = @cc unless @cc.nil?
    @mail.from = @from
    @mail.subject = @subject unless @subject.nil?
    body = add_list_unsubscribe(@body)
    # Note:
    # Content-Transfer-Encoding setting is not required
    # when 'mail-iso-2022-jp' is used.

    # Add format dependent body.
    if (@html == true)
      encode_text_part(remove_html_tag(body))
      encode_html_part(body)
    elsif (@attachments.size > 0)
      encode_text_part(body)
    else
      #@mail.body = (NKF.nkf("--oc=#{CHARSET}", body))
      @mail.body = body
    end
    # Add attachments.
    @attachments.each do |f|
      encode_attachment(f)
    end
  end

  private def remove_html_tag(str)
    str.gsub(%r{</?[^>]+?>}, '')
  end

  private def encode_text_part(body)
    text_part = Mail::Part.new
    # Note:
    # Charset/Content-Transfer-Encoding related settings
    # are not required when 'mail-iso-2022-jp' is used.
    text_part.body = body
    @mail.text_part = text_part
  end

  private def encode_html_part(body)
    html_part = Mail::Part.new
    html_part.content_type = "text/html;charset=UTF-8"
    html_part.body = body
    @mail.html_part = html_part
  end

  private def encode_attachment_unused(file)
    # Note: do not use this since text encoding will not work.
    @mail.add_file(file)
  end

  private def encode_attachment(file)
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
  p m
  p m.to_s
  m.send
end

# vim: sts=2 sw=2 et nowrap
