FROM fedora:33

RUN dnf install -y \
	findutils \
	gcc \
	git \
	libffi-devel \
	mod_auth_openidc \
	openssl-devel \
	patch \
	python3 \
	python3-devel \
	python3-mod_wsgi \
	python3-pip \
	tar

RUN pip install -U \
	pip \
	setuptools

########################################################################
## Horizon
##

ARG HORIZON_VERSION=5eafe66
ARG HORIZON_REPO=https://github.com/openstack/horizon

RUN mkdir -p /opt/horizon
WORKDIR /opt/horizon

RUN curl -sfL -o horizon.tar.gz ${HORIZON_REPO}/archive/${HORIZON_VERSION}.tar.gz && \
	tar -x --strip-components=1 -f horizon.tar.gz && \
	rm -f horizon.tar.gz

COPY tools/horizon-customizations/logo.svg /opt/horizon/openstack_dashboard/static/dashboard/img/logo.svg
COPY tools/horizon-customizations/logo.svg /opt/horizon/openstack_dashboard/static/dashboard/img/logo-splash.svg
COPY tools/horizon-customizations/_splash.html /opt/horizon/openstack_dashboard/templates/auth/_splash.html

# The new pip dependency resolver will complain if horizon's version is
# anything but the one in the contraints file.
RUN PBR_VERSION=19.2.0 pip install -e . \
        -c https://opendev.org/openstack/requirements/raw/branch/stable/wallaby/upper-constraints.txt

########################################################################
## Adjutant
##

ARG ADJUTANT_UI_VERSION=a90963b3
ARG ADJUTANT_UI_REPO=https://github.com/CCI-MOC/adjutant-ui

RUN mkdir -p /opt/adjutant-ui
WORKDIR /opt/adjutant-ui

RUN echo ${ADJUTANT_UI_VERSION} > .version && \
	curl -sfL -o adjutant-ui.tar.gz ${ADJUTANT_UI_REPO}/archive/${ADJUTANT_UI_VERSION}.tar.gz && \
	tar -x --strip-components=1 -f adjutant-ui.tar.gz && \
	rm -f adjutant-ui.tar.gz

RUN PBR_VERSION=${ADJUTANT_UI_VERSION} pip install -e . \
        -r /opt/adjutant-ui/requirements.txt \
        -c https://opendev.org/openstack/requirements/raw/branch/stable/wallaby/upper-constraints.txt

RUN python3 /opt/adjutant-ui/manage.py collectstatic --noinput

########################################################################
## Configure
##

WORKDIR /opt

COPY tools/* /opt/
COPY local/* /opt/horizon/openstack_dashboard/local/
COPY local/enabled/* /opt/horizon/openstack_dashboard/enabled/

# Note(knikolla): This is required to support the random
# user IDs that OpenShift enforces.
# https://docs.openshift.com/enterprise/3.2/creating_images/guidelines.html
RUN sed -i -e "s|Listen 80|Listen 8080|g;" /etc/httpd/conf/httpd.conf
RUN chmod -R g+rwX /opt && \
    chgrp -R 0 /opt && \
    chmod -R g+rwX /run/httpd && \
    chgrp -R 0 /run/httpd && \
    chmod -R g+rwX /etc/httpd/logs && \
    chgrp -R 0 /etc/httpd/logs && \
    chmod -R g+rwX /etc/httpd/conf.d && \
    chgrp -R 0 /etc/httpd/conf.d && \
    chmod g-rwx /opt/horizon/openstack_dashboard/local/.secret_key_store

USER 1001:0

ENTRYPOINT ["/opt/docker-entrypoint.sh"]
CMD ["/usr/sbin/httpd", "-D", "FOREGROUND"]
