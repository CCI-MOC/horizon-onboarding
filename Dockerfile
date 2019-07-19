ARG IMAGE
FROM $IMAGE

# Bug https://bugzilla.redhat.com/show_bug.cgi?id=1694411
RUN echo "zchunk=False" >> /etc/dnf/dnf.conf && \
    dnf install -y gcc httpd python3 python3-pip python3-devel \
        python3-mod_wsgi mod_auth_openidc libffi-devel openssl-devel

# Note(knikolla): Set version higher than what is required by adjutant-ui
ENV PBR_VERSION="15.0.0"
RUN pip3 install -U pip setuptools

# Note(knikolla): Install Horizon
# TODO(knikolla): Use upstream horizon
COPY --chown=1001:0 horizon /opt/horizon
RUN pip3 install -e /opt/horizon && \
    pip3 install python-memcached && \
    python3 /opt/horizon/manage.py collectstatic --noinput

# Note(knikolla): Install Adjutant-UI
ENV PBR_VERSION="0.0.1"
COPY --chown=1001:0 adjutant-ui /opt/adjutant-ui
RUN pip3 install -e /opt/adjutant-ui

# Note(knikolla): Configure
COPY --chown=1001:0 tools/* /opt/
COPY --chown=1001:0 local/* /opt/horizon/openstack_dashboard/local/
COPY --chown=1001:0 local/enabled/* /opt/horizon/openstack_dashboard/enabled/

# Note(knikolla): This is required to support the random
# user IDs that OpenShift enforces.
# https://docs.openshift.com/enterprise/3.2/creating_images/guidelines.html
RUN chmod -R g+rwX /opt && \
    chgrp -R 0 /opt && \
    chmod -R g+rwX /run/httpd && \
    chgrp -R 0 /run/httpd && \
    chmod -R g+rwX /etc/httpd/logs && \
    chgrp -R 0 /etc/httpd/logs && \
    chmod -R g+rwX /etc/httpd/conf.d && \
    chgrp -R 0 /etc/httpd/conf.d && \
    sed -i -e "s|Listen 80|Listen 8080|g;" /etc/httpd/conf/httpd.conf

EXPOSE 8080
USER 1001:0

ENTRYPOINT ["/opt/run_horizon.sh"]
