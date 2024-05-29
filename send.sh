#!/bin/sh
$(dirname $(realpath $0))/setup.sh
bundle exec MailThis.rb $*
