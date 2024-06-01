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
  CONFIG = {
    'smtp_server_address' => nil,
    'smtp_server_port' => 587, # 587 is well known port for SMTP.
    'smtp_authentication' => 'plain', # 'plain', 'login' or 'cram_md5'.
    'smtp_enable_tls' => true, # Use TLS for SMTP connection.
    'smtp_validate_ssl' => true, # Validate SSL certificate or not.
    'smtp_user_name' => nil,
    'smtp_pass' => nil,
    'from_address' => nil,
    'charset' => 'ISO-2022-JP', # Expected character-set used for text/plain part of the message body.
    'list_unsubscribe_base' => '',
    'verbose' => 'true', # For debug: increase debug messages.
    'dry_run' => false # To debug internal algorithm: when 'true', skip sending E-mail.
  }
  def initialize(filename = "config.json")
    # Set default values.
    import_hash(CONFIG)
    # Import members from constants.
    import_const()
    # Import members from configuration file.
    File.exist?(filename) and File.open(filename) do |j|
      import_hash(JSON.load(j))
    end
    validate()
  end

  private def validate()
    raise "smtp_enable_tls shall be bool" unless is_bool?(@smtp_enable_tls)
    raise "smtp_server_port shall be int" unless @smtp_server_port.is_a?(Integer)
    raise "smtp_server_address is not defined" unless defined?(@smtp_server_address)
  end

  private def import_hash(hash)
    return unless hash.is_a?(Hash)
    CONFIG.keys.each do |key|
      add_variable(key, hash[key]) if hash.has_key?(key)
    end
  end

  private def import_const()
    CONFIG.keys.each do |key|
      val = key.upcase
      add_variable(key, eval("#{val}")) if eval("defined?(#{val})")
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
  attr_writer :from, :password, :user_name, # SMTP parameters
    :to, :cc, :subject, :list_unsubscribe_unique, # Headers
    :body, :is_html, # Message-body parameters
    :log, :name,

  def import_header(name, line)
    # Import header from single line.
    if eval("line =~ /^#{name}:/") then
      val = name.gsub('-','_')
      eval("@#{val} = line.sub(/^#{name}:\s+/i, '')")
      return true
    end
    return false
  end

  def analyze_file(filename)
    # Import a body and headers from the file.
    File.exist?(filename) and File.open(filename) do |f|
      while l = f.gets.strip do
        if l =~ /^$/ then
          break
        end
        for header in ['subject', 'to', 'cc', 'list-unsubscribe-unique'] do
          break if import_header(header, l)
        end
      end
      @body = f.read
      @is_html = true if (filename =~ /\.html*$/)
    end
  end

  def initialize(filename = nil, config_fn = 'config.json', &block)
    @config = MailConfig.new(config_fn)
    @list_unsubscribe_unique = nil
    @attachments = Array.new
    @log = nil
    @from = @config.from_address
    @user_name = @config.smtp_user_name
    @password = @config.smtp_pass
    @is_html = false
    analyze_file(filename) unless filename.nil?
    block.call if block_given?
  end

  def add_attachment(file)
    @attachments.push(file)
  end

  def send
    # Check necessary fields.
    raise "no @from" if @from.nil?
    raise "no @to" if @to.nil?
    raise "no @subject" if @subject.nil?
    raise "no @user_name" if @user_name.nil?
    raise "no @password" if @password.nil?
    raise "no @body" if @body.nil?

    # Note: encode everytime, since the body can include unsubscribe link.
    encode_message

    if @config.smtp_validate_ssl
      ssl_verify_mode = nil
    else
      ssl_verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
    opt = {
      :address => @config.smtp_server_address,
      :port => @config.smtp_server_port,
      :authentication => @config.smtp_authentication.to_sym,
      :enable_starttls_auto => @config.smtp_enable_tls,
      :user_name => @user_name,
      :password => @password,
      :openssl_verify_mode => ssl_verify_mode,
    }
    @mail.delivery_method(:smtp, opt)

    show_log("Sending from #{@from.to_s} to #{@name} <#{@to.to_s}>...")
    @mail.deliver! unless @config.dry_run
    show_log(@mail.to_s) if @config.verbose
    show_log('Done!')
  end

  def to_s
    "body=#{@body},subject=#{@subject},to=#{@to},mail=#{@mail.to_s}"
  end

  private def show_log(str)
    @log.puts(str) if @log.respond_to?(:puts)
    STDERR.puts(str)
  end

  private def add_list_unsubscribe(body)
    return body if @list_unsubscribe_unique.nil?
    link = @config.list_unsubscribe_base + @list_unsubscribe_unique
    @mail.header['List-Unsubscribe'] = "<#{link}>"
    @mail.header['List-Unsubscribe-Post'] = 'List-Unsubscribe=One-Click'
    return body.gsub(/\$LIST_UNSUBSCRIBE_LINK/, link)
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
    if (@is_html == true)
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
    str.gsub(%r{<!--.*?-->}m, '').gsub(%r{</?[^>]+?>}, '')
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
  m.send
end

# vim: sts=2 sw=2 et nowrap
