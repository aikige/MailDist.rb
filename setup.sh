#!/bin/sh
SCRIPT_DIR=$(dirname $(realpath $0))
BUNDLE_DIR=.bundle
if [ -d $BUNDLE_DIR ]; then
	exit
fi
if [ ! -f Gemfile ]; then
	ln -s $SCRIPT_DIR/Gemfile
fi
bundle install --path $BUNDLE_DIR
