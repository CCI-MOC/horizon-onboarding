#!/bin/bash
cp /opt/horizon.conf /etc/httpd/conf.d/horizon.conf
sed -i -e "
    s|%HORIZON_URL%|$HORIZON_URL|g;
    s|%OPENSTACK_REGISTRATION_URL%|$OPENSTACK_REGISTRATION_URL|g;
    s|%OIDC_METADATA_URL%|$OIDC_METADATA_URL|g;
    s|%OIDC_CLIENT_ID%|$OIDC_CLIENT_ID|g;
    s|%OIDC_CLIENT_SECRET%|$OIDC_CLIENT_SECRET|g;
    " /etc/httpd/conf.d/horizon.conf

rm -rf /run/httpd/* /tmp/httpd*
/usr/sbin/httpd -D FOREGROUND