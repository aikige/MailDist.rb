# MailDist

Simple ruby script to distribute E-mail.

## Getting started

1. Please place following items.
	1. Address.csv
	1. Password.csv
	1. Message.txt
1. Run MailDist.rb
1. Then the script distributes contents written in Message.txt to addresses written in Address.csv using account information written in Password.csv.

## Options

* -m FILE / --message=FILE: specify name of Message file. By default `Message.txt` is used.
* -p FILE / --password=FILE: specify name of Password CSV file. By default, `Password.csv` is used.
* -c FILE / --contacts=FILE: specify name of Contract list CSV file. By default, `Address.csv` is used.
* -a FILE / --attachment=FILE: if this option is used, read file and attach it to the E-mail.

## Message Format

1st line of the `Message.txt` is used as Subject of the E-mail.

## CSV format

### Address.csv

CSV file should include either of following format.

Note: title row is needed.

|Name|From|Flag|Address|Flag|
|----|----|----|-------|----|
|Name of destination|address used in from field|send|address@of.distination|send|

|Name|Range|Flag|Address|Flag|
|----|-----|----|-------|----|
|Name of destination|Range_ID|send|address@of.distination|send|

In the 2nd format, user can specify *FROM* field using *Range_ID*, this *Range_ID* should be written in Password.csv in this case.

### Password.csv

This script is expecting that SMTP server requires authentication. `Password.csv` is used to provide authentication information needed to send E-mail using the address.

|Address|UID|Password|
|-------|---|--------|
|hoge@hoge.com|hogehoge|piyopiyo|

if you are using *Range_ID* to specify from field.
This file needs *Range* field.

|Address|UID|Password|Range|
|-------|---|--------|-----|
|hoge@hoge.com|hogehoge|piyopiyo|1|
|fuga@hoge.com|fugafuga|piyohoge|2|

## Retrieve Address.csv from Google Drive (Spreadsheet)

The script `ExportGS2CSV.rb` allow you to download Address.csv from Google Spreadsheet.

Syntax: `ExportGS2CSV.rb -f $FILE_ID -o $OUTPUT_CSV`

* `$FILE_ID`: the file ID for the google spreadsheet.
* `$OUTPUT_CSV`: the output filename, in this case `Address.csv` is recommended.

### Preparation to run the script

1. Please retrieve `credentials.json` from Google and place it on the folder where you run the script.
    Please refer: https://developers.google.com/drive/api/v3/quickstart/ruby
	and follow the step `ENABLE THE DRIVE API` to retrieve the JSON file.
1. Executed this script on your folder.
1. Follow the instruction of this script. Usually it requests you to access specific URI and paste Authentication String to the script.

### Note about ExportGS2CSV.rb

This scripts request you to provide read-only file access to your google drive.
Please be careful.
