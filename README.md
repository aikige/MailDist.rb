# MailThis.rb

A simple ruby script to send Japanese Text message.

## Getting Started

1. Please prepare following items:
	1. config.rb - configuration file which gives server information, including password.
	1. Any message text, which is using UTF-8 as file encoding (*.txt or *.html)
1. Executed script <br />
	`./MailThis.rb FILENAME`
1. Then you'll get E-mail sent.

## Message format

The message format is as follows

```
to: sample@example.com
subject: subject.

Message body.
```

Message should include header part which gives `To` header and `Subject` header used by E-mail (For meantime, `Cc` field is not supported).

If you want to send HTML formatted E-mail, please use '.html' extension for the filename. The script determines input data format between `text/plain` and `text/html` based on extension.
