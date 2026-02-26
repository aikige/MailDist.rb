#!/bin/sh
SCRIPT_DIR=$(dirname $(realpath $0))
BUNDLE_DIR=.bundle
if [ ! -f Gemfile ]; then
	ln -s $SCRIPT_DIR/Gemfile
fi
bundle config set --local path $BUNDLE_DIR
bundle install
