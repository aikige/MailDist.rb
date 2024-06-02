#!/usr/bin/env ruby

require 'csv'
require 'optparse'
require 'date'
require 'io/console'
require 'openssl'
require 'base64'

require_relative 'MailThis'

def show_log(str, no_newline = false)
  puts(str)
  if (no_newline)
    STDERR.print(str)
  else
    STDERR.puts(str)
  end
end

def get_password(msg)
  password = IO::console.getpass msg
  return password
end

# Reference: https://qiita.com/kou_pg_0131/items/f5ce9fec5c9b772dbeff
def encrypt_string(plain_text, password)
  salt = OpenSSL::Random.random_bytes(8)
  enc = OpenSSL::Cipher::AES.new(256, :CBC)
  enc.encrypt

  key_iv = OpenSSL::PKCS5.pbkdf2_hmac(password, salt, 2000, enc.key_len + enc.iv_len, "sha256")
  enc.key = key_iv[0, enc.key_len]
  enc.iv = key_iv[enc.key_len, enc.iv_len]

  encrypted_text = enc.update(plain_text) + enc.final
  
  encrypted_text = Base64.encode64(encrypted_text).chomp
  salt = Base64.encode64(salt).chomp

  return encrypted_text, salt
end

def decrypt_string(encrypted_text, salt, password)
  encrypted_text = Base64.decode64(encrypted_text)
  salt = Base64.decode64(salt)

  dec = OpenSSL::Cipher::AES.new(256, :CBC)
  dec.decrypt

  key_iv = OpenSSL::PKCS5.pbkdf2_hmac(password, salt, 2000, dec.key_len + dec.iv_len, "sha256")
  dec.key = key_iv[0, dec.key_len]
  dec.iv = key_iv[dec.key_len, dec.iv_len]

  return dec.update(encrypted_text) + dec.final
end

def encrypt_password_file(csv_file)
  csv = CSV.read(csv_file, headers: true)

  # Decrypt first.
  master_password = nil
  csv.each do |row|
    unless row['Salt'].nil? or row['EncPassword'].nil? then
      master_password = get_password('Enter Current Master Password: ') if master_password.nil?
      row['Password'] = decrypt_string(row['EncPassword'], row['Salt'], master_password)
    end
  end

  master_password = get_password('Enter New Master Password: ')

  # Encrypt
  csv.each do |row|
    row['EncPassword'], row['Salt'] = encrypt_string(row['Password'], master_password)
    row.delete('Password')
  end

  # Write Updated Item
  File.write(csv_file, csv)
end

address_csv = 'Address.csv'
password_csv = 'Password.csv'
message_file = 'Message.txt'
log_file = "#{Date.today.strftime('%Y%m%d')}.log"
attach_files = Array.new
flag = nil
update_encrypt = false
list_unsubscribe = false

# Option
opt = OptionParser.new
opt.on('-m FILE', '--message=FILE', "Set message file. (default: #{message_file})") { |v| message_file = v }
opt.on('-p FILE', '--password=FILE', "Set password file. (default: #{password_csv})") { |v| password_csv = v }
opt.on('-c FILE', '--contacts=FILE',
  "Set contact list (address book). File shall be CSV format. (default: #{address_csv})") { |v| address_csv = v }
opt.on('-a FILE', '--attachment=FILE', 'Add attachment file.') { |v| attach_files.push(v) }
opt.on('-f FLAG', '--flag=FLAG', 'Set flag to select user.') { |v| flag = v }
opt.on('-e', '--encrypt', 'Encrypt password in password file.') { |v| update_encrypt = true }
opt.on('-l', '--list-unsubscribe', 'Enable List-Unsubscribe header.') { |v| list_unsubscribe = true }
opt.parse!(ARGV)

# Log File
$stdout = File.open(log_file, "a")

if update_encrypt then
  # Update Password Encryption and Quit
  encrypt_password_file(password_csv)
  show_log('password encryption updated')
  exit
end

# Read password database.
range_to_addr = Hash.new
addr_to_uid = Hash.new
uid_to_pass = Hash.new
master_password = nil
pdb = CSV.read(password_csv, headers: true)
pdb.each do |row|
  range_to_addr[row['Range']] = row['Address'] unless row['Range'].nil?
  addr_to_uid[row['Address']] = row['UID']
  if row['Salt'].nil? or row['EncPassword'].nil? then
    uid_to_pass[row['UID']] = row['Password']
  else
    master_password = get_password('Enter Master Password: ') if master_password.nil?
    uid_to_pass[row['UID']] = decrypt_string(row['EncPassword'], row['Salt'], master_password)
  end
end

# Prompt before send.
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
  mail.name = usr['Name']
  if list_unsubscribe
    mail.list_unsubscribe_unique = "from=#{usr['Address']}".gsub(/@/, '%40')
  end
  mail.send
end

show_log('Finish!')

# vim: sts=2 sw=2 et nowrap
