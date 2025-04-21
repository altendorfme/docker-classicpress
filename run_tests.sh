#!/usr/bin/env sh
apk --no-cache add curl
for i in $(seq 1 10); do curl -fs classicpress > /dev/null && break || { echo -n '.'; sleep 1; }; done;
curl --silent --fail http://classicpress/wp-admin/install.php | grep 'wp-core-ui'
