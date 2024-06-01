# `MailThis.rb`

A simple ruby script to send text message.

## Getting Started (requires Bundler)

1. Precondition<br>
   If you don't have [Bundler] installed, please execute following:
    ```
    gem install bundler
    ```
1. Setup
    1. Clone this repository.
    1. Execute `setup.sh` &mdash; this will execute `bundle install`.
    1. Copy `config_example.json` to `config.json`
    1. Edit `config.json` to adjust your environment.
1. Daily Use
    1. Execute `send.sh` if you want to try `MailThis.rb`.
    1. Execute `dist.sh` if you want to execute mail distribution via `MailDist.rb`.

## Getting Started (without Bundler)

[Bundler]:https://bundler.io/

1. Please install ruby and dependent library
	1. Usually, you need to do following
        ```
        gem install mail-iso-2022-jp
        gem install mime-types
        ```
1. Please prepare following items:
	1. `config.json` - configuration file which gives server information, including password.
	1. Any message text, which is using UTF-8 as file encoding (`*.txt` or `*.html`)
1. Executed script. If you are going to send `Message.txt` please execute following
    ```
    ruby MailThis.rb Message.txt
    ```
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

## Configuration file format

`config.json` is a JSON data used to set several parameters which are used by `MailThis.rb`

For example, in the case of Gmail:

```
{
    "smtp_server_address": "smtp.gmail.com",
    "smtp_server_port": 587,
    "smtp_enable_tls": true,
    "smtp_authentication": "login",
    "smtp_user_name": "example@gmail.com",
    "smtp_pass": "xxxxxxxx",
    "from_address": "example@gmail.com",
    "charset": "iso-2022-JP",
	"list_unsubscribe_base": "https://script.google.com/macros/s/XXXX/exec?",
	"validate_ssl": true
}
```

### Configuration keys

|Key|Mandatory?|Value Type|Description|
|---|:-------:|----------|-----------|
|`smtp_server_address`  |M|string |IP address or host-name of the SMTP server.|
|`smtp_server_port`     |O|decimal|Port number of the SMTP server. Default value is `587`.|
|`smtp_authentication`  |O|string |The value should be `plain`, `login` or `cram_md5`. Please refer `authtype` option of the back-end [Net::SMTP.start](https://docs.ruby-lang.org/ja/latest/method/Net=3a=3aSMTP/s/start.html). The default value is `plain`.|
|`smtp_enable_tls`      |O|boolean|When this value is `true`, enables TLS connection for SMTP. The default value is `true`.|
|`smtp_validate_ssl`         |O|boolean|When this value is `false`, application skips validation of SSL certificate. The default value is `true`.|
|`smtp_user_name`       |C|string |Default user name for SMTP authentication.|
|`smtp_pass`            |C|string |Default password for SMTP authentication.|
|`from_address`         |C|string |Default mail address used for `From:` header of the message.|
|`charset`              |O|string |Charter-set used as encoding of body. The default value is "ISO-2022-JP".|
|`list_unsubscribe_base`|O|string |Base address of List-Unsubscribe URL. The default value is "" &mdash; empty string.|

This script assumes that SMTP requires some sort of authentication.
SMTP without authentication is not supported.

Keys categorized as "C" in the table become default values of `MailThis` attributes for sending messages.
Following table shows mapping between configuration keys and attributes.

|Configuration key|Attribute|
|:----------------|:----------|
|`smtp_pass`|`password`|
|`smtp_user_name`|`user_name`|
|`from_address`|`from`|

## RFC 8058 Support

If the `MailThis` object has non-null `list_unsubscribe_unique` attribute,
this script generates `List-Unsubscribe` and `List-Unsubscribe-Post` header based on `list_unsubscribe_unique` and `list_unsubscribe_base` attribute in configuration.

The `list_unsubscribe_unique` attribute can be set either of following manner:
- Include `list-unsubscribe-unique:` header in the message.
- Set attribute via its accessor.

Additionally, the text `$LIST_UNSUBSCRIBE_LINK` in the message is replaced by the value of `List-Unsubscribe` header.

```
LIST_UNSUBSCRIBE_LINK = list_unsubscribe_base + list_unsubscribe_unique
```

## Use `MailThis.rb` as python module

### Basic Usage

```ruby
require 'MailThis'
mail = MailThis.new
mail.body = "This is a body of a sample message."
mail.subject = "Sample message"
mail.from = "src@example.com"
mail.to = "dst@example.com"
mail.send() # send the message.
```
or
```ruby
require 'MailThis'
mail = MailThis.new do
  @body = "This is a body of a sample message."
  @subject = "Sample message"
  @from = "src@example.com"
  @to = "dst@example.com"
  send()
end
```

### Sample Script

`MailThis.rb` can be used as module, and `MailDist.rb` provides example how to use it.

This script can be used to distribute E-mail based on address list `Address.csv`.

For detail about `MailDist.rb`, please check [`MailDist.md`](MailDist.md).
