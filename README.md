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

## CSV format

### Address.csv

CSV file should include either of following format.

Note: title row is needed.

|Name|From|Flag|Address|
+----+----+----+-------+
|Name of destination|address used in from field|send|address@of.distination|

|Name|Range|Flag|Address|
+----+----+----+-------+
|Name of destination|Range_ID|send|address@of.distination|

In the 2nd format, user can specify _FROM_ field using _Range_ID_, this _Range_ID_ should be written in Password.csv in this case.
