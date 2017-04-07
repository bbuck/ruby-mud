#!/usr/bin/env bash

sudo -u vagrant bash --login <<'SETUP'
  rvm install ruby-2.2.1
  cd /vagrant

  # Install bundler and bundled gems
  gem install bundler
  bundle install

  # setup database
  rake db:create
  rake db:migrate

  bin/laeron super_admin --username=admin --password=password
  bin/laeron server &
SETUP
