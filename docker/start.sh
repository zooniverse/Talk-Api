#!/bin/bash -ex

if [ -z "$VAGRANT_APP" ]
then
    ln -s /rails_conf/* /rails_app/config/
fi

exec /usr/bin/supervisord -c /etc/supervisor/conf.d/talk.conf
