#!/bin/sh
$(dirname $(realpath $0))/setup.sh
bundle exec MailDist.rb -l $*
