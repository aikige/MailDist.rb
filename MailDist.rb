#!/usr/bin/env ruby

#require 'mail'
require 'mail-iso-2022-jp'
require 'csv'
require 'optparse'
require 'nkf'
require 'date'

# Load server configuration from 'server.rb' or use deault value.
begin
  require_relative('server')
rescue LoadError
  SMTP_SERVER_ADDRESS = 'seishin-kan.sakura.ne.jp'
  SMTP_SERVER_PORT = 587
  SMTP_DOMAIN = 'seishin-kan.com'
  SMTP_ENABLE_TLS = true
end

TEST_FORMAT = false

address_csv = 'Address.csv'
password_file = 'Password.txt'
password_csv = 'Password.csv'
message_file = 'Message.txt'
log_file = "#{Date.today.strftime('%Y%m%d')}.log"
attach_file = nil
flag = nil

def show_log(str)
  puts(str)
  STDERR.puts(str)
end

# Force Base64 encoding for attachment.
def attach_file1(mail, attach_file)
  body = File.binread(attach_file)
  type = MIME::Types.type_for(attach_file)[0].to_s
  if type =~ /text\/.*/ then
    # Note: workaround - Mail tend to add 'charset=UTF8' for
    # the text files without checking actual charset of the file.
    # So, this script puts type manually.
    # NKF gives better suggestion than String::encoding
    type += ";charset=#{NKF.guess(body).to_s}"
  end
  mail.attachments[attach_file] = {
    :content_type => type,
    :content_transfer_encoding => 'base64',
    :content => Base64.encode64(body), # Note: need to encode manually.
  }
#  p mail.attachments[attach_file]
  return mail
end

# Default, but not good.
def attach_file2(mail, attach_file)
  mail.add_file(attach_file)
  return mail
end

def send_mail(from, to, subject, body, uid, passwd, attach_file)
  mail = Mail.new(:charset => 'ISO-2022-JP')
  mail.from(from)
  mail.to(to)
  mail.subject(subject)
  unless attach_file.nil? then
    # Create multipart/mixed style.
    part = Mail::Part.new
#    part.content_type('text/plain; charset=iso-2022-jp') # Should not do this!
    part.body(body)
    mail.text_part = part
    mail = attach_file1(mail, attach_file)
  else
    # Single part. Just add body.
    mail.body(body)
  end
  options = {
    :address => SMTP_SERVER_ADDRESS,
    :port => SMTP_SERVER_PORT,
    :domain => SMTP_DOMAIN,
    :user_name => uid,
    :password => passwd,
    :tsl => SMTP_ENABLE_TLS
  }
  puts mail.to_s if TEST_FORMAT == true
  mail.delivery_method(:smtp, options)
  show_log("Sending from #{from.to_s} to #{to.to_s}...")
  mail.deliver! unless TEST_FORMAT == true
  show_log('Done!')
end

# Option
opt = OptionParser.new
opt.on('-m FILE', '--message=FILE', "Set message file. (default: #{message_file})") { |v| message_file = v }
opt.on('-p FILE', '--password=FILE', "Set password file. (default: #{password_csv})") { |v| password_csv = v }
opt.on('-c FILE', '--contacts=FILE',
  "Set contact list (address book). File shall be CSV format. (default: #{address_csv})") { |v| address_csv = v }
opt.on('-a FILE', '--attachment=FILE', 'Add attachment file.') { |v| attach_file = v }
opt.on('-f FLAG', '--flag=FLAG', 'Set flag to select user.') { |v| flag = v }
opt.parse!(ARGV)

# Log File
$stdout = File.open(log_file, "a")

# Retrieve message subject and body.
f = File.open(message_file)
subject=f.gets.chomp
body=f.read
f.close

# Read password database.
range_to_addr = Hash.new
addr_to_uid = Hash.new
uid_to_pass = Hash.new
p = CSV.read(password_csv, headers: true)
p.each do |e|
  range_to_addr[e['Range']] = e['Address'] unless e['Range'].nil?
  addr_to_uid[e['Address']] = e['UID']
  uid_to_pass[e['UID']] = e['Password']
end

# Prompt before send.
STDERR.print('Are you sure to send? (y/n)> ')
ans = gets
unless ans.downcase.include?('y')
  STDERR.puts('quit...')
  exit
end

# Send message to all user listed in CSV.
database = CSV.read(address_csv, headers: true)
database.each do |usr|
  from = range_to_addr[usr['Range']] unless usr['Range'].nil?
  from = usr['From'] unless usr['From'].nil? if from.nil?
  uid = addr_to_uid[from] unless from.nil?
  if uid.nil? then
    show_log("No destination for #{usr['Name']}")
    next
  end

  passwd = uid_to_pass[uid]
  if passwd.nil? then
    show_log("No password for #{usr['Name']}")
    next
  end

  # Check flag and skip if needed.
  if usr['Flag'].nil? or !(usr['Flag'].include?('send')) then
    show_log("Skip #{usr['Name']}:#{usr['Flag']}")
    next
  end
  unless flag.nil? or usr['Flag'].include?(flag) then
    show_log("Skip #{usr['Name']}:#{usr['Flag']}/#{flag}")
    next
  end

  # Skip if address is not available.
  if usr['Address'].nil? or !(usr['Address'].include?('@')) then
    show_log("Invalid Address for #{usr['Name']}:#{usr['Address']}")
    next
  end

  send_mail(from, usr['Address'], subject, body, uid, passwd, attach_file)
end
show_log('Finish!')

# vim: sts=2 sw=2 et
