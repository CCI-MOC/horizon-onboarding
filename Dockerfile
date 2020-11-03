FROM fedora:31

# Bug https://bugzilla.redhat.com/show_bug.cgi?id=1694411
RUN echo "zchunk=False" >> /etc/dnf/dnf.conf && \
    dnf install -y git gcc httpd python3 python3-pip python3-devel \
        python3-mod_wsgi mod_auth_openidc libffi-devel openssl-devel

RUN pip3 install -U pip setuptools

# Install Horizon
ARG HORIZON_VERSION=6199c5fd
ARG HORIZON_REPO=https://github.com/openstack/horizon

WORKDIR /opt
RUN git clone ${HORIZON_REPO}

WORKDIR /opt/horizon
RUN git checkout ${HORIZON_VERSION}

# Patch for https://github.com/CCI-MOC/ops-issues/issues/4
COPY 0001-handle-missing-access_rules.patch .
RUN git apply 0001-handle-missing-access_rules.patch

COPY tools/horizon-customizations/logo.svg /opt/horizon/openstack_dashboard/static/dashboard/img/logo.svg
COPY tools/horizon-customizations/logo.svg /opt/horizon/openstack_dashboard/static/dashboard/img/logo-splash.svg
COPY tools/horizon-customizations/_splash.html /opt/horizon/openstack_dashboard/templates/auth/_splash.html

RUN pip install -e /opt/horizon/ \
        -c https://opendev.org/openstack/requirements/raw/branch/master/upper-constraints.txt

# Note(knikolla): Install Adjutant-UI
ENV PBR_VERSION="0.0.1"
COPY --chown=1001:0 adjutant-ui /opt/adjutant-ui
RUN pip3 install -e /opt/adjutant-ui \
        -r /opt/adjutant-ui/requirements.txt \
        -c https://opendev.org/openstack/requirements/raw/branch/master/upper-constraints.txt

RUN python3 /opt/adjutant-ui/manage.py collectstatic --noinput

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
