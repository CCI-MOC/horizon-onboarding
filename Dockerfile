FROM centos/python-36-centos7

MAINTAINER "Kristi Nikolla <knikolla@bu.edu>"

ENV PBR_VERSION 0.1

LABEL io.k8s.description="MOC Onboarding Dashboard built on Horizon" \
      io.k8s.display-name="Onboarding-UI" \
      io.openshift.expose-services="8080:http" \


COPY ./.s2i/bin/ /usr/libexec/s2i

USER 1001

EXPOSE 8080
