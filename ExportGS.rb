#!/usr/bin/env ruby

require 'google/apis/drive_v3'
require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'fileutils'
require 'csv'
require 'optparse'

OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'.freeze
APPLICATION_NAME = 'Export Spreadsheet as CSV'.freeze
CREDENTIALS_PATH = 'credentials.json'.freeze
# The file token.yaml stores the user's access and refresh tokens, and is
# created automatically when the authorization flow completes for the first
# time.
TOKEN_PATH = 'token.yaml'.freeze
#SCOPE = Google::Apis::DriveV3::AUTH_DRIVE_FILE
SCOPE = Google::Apis::DriveV3::AUTH_DRIVE_READONLY
# Note: AUTH_DRIVE_READONLY should be selected if the source file is not created by this script.

##
# Ensure valid credentials, either by restoring from the saved credentials
# files or intitiating an OAuth2 authorization. If authorization is required,
# the user's default browser will be launched to approve the request.
#
# @return [Google::Auth::UserRefreshCredentials] OAuth2 credentials
def authorize
  client_id = Google::Auth::ClientId.from_file(CREDENTIALS_PATH)
  token_store = Google::Auth::Stores::FileTokenStore.new(file: TOKEN_PATH)
  authorizer = Google::Auth::UserAuthorizer.new(client_id, SCOPE, token_store)
  user_id = 'default'
  credentials = authorizer.get_credentials(user_id)
  if credentials.nil?
    url = authorizer.get_authorization_url(base_url: OOB_URI)
    puts "Open the following URL in the browser and enter the resulting code after authorization:\n" + url
    code = gets
    credentials = authorizer.get_and_store_credentials_from_code(
      user_id: user_id, code: code, base_url: OOB_URI
    )
  end
  credentials
end

def is_valid(dat)
	return false if dat['ID'].nil? or dat['Type'].nil? or dat['Filename'].nil?
	return true
end

config_fn = 'Files.csv'

opt = OptionParser.new
opt.on('-c FILE', '--config=FILE', "Set configuration file . (default: #{config_fn})") { |v|
	config_fn = v
}
opt.parse!(ARGV)

config_db = CSV.read(config_fn, headers: true)

# Initialize the API
drive_service = Google::Apis::DriveV3::DriveService.new
drive_service.client_options.application_name = APPLICATION_NAME
drive_service.authorization = authorize

config_db.each { |obj|
	result = drive_service.export_file(obj['ID'], obj['Type'], download_dest: obj['Filename']) if is_valid(obj)
}
