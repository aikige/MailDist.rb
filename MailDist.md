# MailDist

Simple ruby script to distribute E-mail.

## Getting started

1. Please place following items.
	1. Address.csv
	1. Password.csv
	1. Message.txt
1. Run MailDist.rb
1. Then the script distributes contents written in Message.txt to addresses written in Address.csv using account information written in Password.csv.

## Synopsis

```
MailDist.rb [-m MESSAGE_FILE] [-p PASSWORD_FILE] [-c CONTACT_LIST_FILE] [-a ATTACH_FILE]
```

## Options

* `-m MESSAGE_FILE` / `--message=MESSAGE_FILE`: specify name of Message file. By default `Message.txt` is used.
* `-p PASSWORD_FILE`/ `--password=PASSWORD_FILE`: specify name of Password CSV file. By default, `Password.csv` is used.
* `-c CONTACT_LIST_FILE`/ `--contacts=CONTACT_LIST_FILE`: specify name of Contact List CSV file. By default, `Address.csv` is used.
* `-a ATTACH_FILE`/ `--attachment=ATTACH_FILE`: if this option is used, read file and attach it to the E-mail.
	It is possible to use multiple `-a` option to attach multiple files.

## Message Format

Please follow message format used by [`MailThis.rb`](README.md).

## CSV format

### Address.csv

CSV file should include either of following format.

Note: title row is needed.

|Name|From|Flag|Address|Flag|
|----|----|----|-------|----|
|Name of destination|address used in from field|send|address@of.distination|send|

|Name|Range|Flag|Address|Flag|
|----|-----|----|-------|----|
|Name of destination|Range ID|send|address@of.distination|send|

In the 2nd format, user can specify *FROM* field using *Range_ID*, this *Range_ID* should be written in Password.csv in this case.

If you want to manage this CSV file under Google Drive, please consider to use [`ExportGS.rb`](ExportGS.md).

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

#### For those who do not want to save plain text passwords

If you execute `MailDist.rb` with `-e` option, it will encrypt passwords using AES-256 with a *Master Password*.
By this operation, *Password* field in the `Password.csv` will be replaced to *EncPassword* and *Salt*.

Once you encrypt password file, you need to enter the *Master Password* to run this script, since the `Password.csv` does not store *Master Password*.
