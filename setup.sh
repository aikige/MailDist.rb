#!/bin/sh
SCRIPT_DIR=$(cd $(dirname $0); pwd)
if [ ! -f Gemfile ]; then
	ln -s $SCRIPT_DIR/Gemfile
fi
bundle install --path .bundle
