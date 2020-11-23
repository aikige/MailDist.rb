# `MailThis.rb`

A simple ruby script to send text message.

## Getting Started

1. Please install ruby and dependent library:
	1. Usually, you need to do following

	```
	gem install mail-iso-2022-jp
	gem install mime-types
	```

1. Please prepare following items:
	1. `config.json` - configuration file which gives server information, including password.
	1. Any message text, which is using UTF-8 as file encoding (*.txt or *.html)
1. Executed script.
1. Then you'll get E-mail sent.

## Synopsis

```
MailThis.rb FILENAME(s)
```

* The first file is used as header and body generation.
  For detail, plese check [Message format](#message-format) below.
* If you specify multiple filename, 2nd or succeeding files are treated as attachment file.

## Message format

The message format is as follows

```
to: sample@example.com
subject: sample subject

Message body.
```

1. The input file shall be encoded by UTF-8.
1. Message should include header part which gives `To` header and `Subject` header used by E-mail, and optionally include `Cc` header.
1. Header part and Body part is separated by null-line.

If you want to send HTML formatted E-mail, please use '.html' extension for the filename.
The script determines input data format between `text/plain` and `text/html` based on extension.

## Configuration file (`config.json`) format

`config.json` is simple JSON data used to set several constants which is used by `MailThis.rb`

For example, in the case of Gmail:

```
{
    "smtp_server_address" = "smtp.gmail.com"
    "smtp_server_port" = 587
    "smtp_enable_tls" = true
    "smtp_user_name" = "example@gmail.com"
    "smtp_pass" = "xxxxxxxx"
    "from_address" = "example@gmail.com"
    "charset" = "iso-2022-JP"
    "debug" = true
}
```

## Sample to use `MailThis.rb` as module - `MailDist.rb`

`MailThis.rb` can be used as module, and `MailDist.rb` provides example how to use it.

This script can be used to distribute E-mail based on address list `Address.csv`.

For detail about `MailDist.rb`, please check [`MailDist.md`](MailDist.md).
