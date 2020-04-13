#!/usr/bin/env ruby

require 'csv'
require 'optparse'
require 'date'

require_relative 'MailThis'

address_csv = 'Address.csv'
password_csv = 'Password.csv'
message_file = 'Message.txt'
log_file = "#{Date.today.strftime('%Y%m%d')}.log"
attach_files = Array.new
flag = nil

def show_log(str, no_newline = false)
  puts(str)
  if (no_newline)
    STDERR.print(str)
  else
    STDERR.puts(str)
  end
end

# Option
opt = OptionParser.new
opt.on('-m FILE', '--message=FILE', "Set message file. (default: #{message_file})") { |v| message_file = v }
opt.on('-p FILE', '--password=FILE', "Set password file. (default: #{password_csv})") { |v| password_csv = v }
opt.on('-c FILE', '--contacts=FILE',
  "Set contact list (address book). File shall be CSV format. (default: #{address_csv})") { |v| address_csv = v }
opt.on('-a FILE', '--attachment=FILE', 'Add attachment file.') { |v| attach_files.push(v) }
opt.on('-f FLAG', '--flag=FLAG', 'Set flag to select user.') { |v| flag = v }
opt.parse!(ARGV)

# Log File
$stdout = File.open(log_file, "a")

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
show_log('server: ' + SMTP_SERVER_ADDRESS)
show_log('message: ' + message_file)
show_log('address: ' + address_csv)
show_log('password: ' + password_csv)
show_log('attachment: ' + attach_files.to_s) if (attach_files.size > 0)
show_log('Are you sure to send? (y/n)> ', true)
ans = gets
unless ans.downcase.include?('y')
  show_log('quit...')
  exit
end

mail = MailThis.new(message_file)
mail.log = $stdout
attach_files.each do |a|
  mail.add_attachment(a)
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

  mail.to = usr['Address']
  mail.from = from
  mail.user_name = uid
  mail.password = passwd
  mail.send(false)
end

show_log('Finish!')

# vim: sts=2 sw=2 et
