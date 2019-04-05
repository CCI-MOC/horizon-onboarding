#!/usr/bin/env bash
s2i build . centos/python-36-centos7 onboarding-ui -c --loglevel=5 --scripts-url file://.s2i/bin
