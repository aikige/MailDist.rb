# MailDist

Simple ruby script to distribute E-mail.

## Getting started

1. Please place following items.
	1. Address.csv
	2. Password.csv
	3. Message.txt
2. Run MailDist.rb
3. Then the script distributes contents written in Message.txt to addresses written in Address.csv using account information written in Password.csv.

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

