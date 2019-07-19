#!/bin/bash
cd ..

docker build . --build-arg IMAGE=fedora:30 -t massopencloud/horizon-onboarding:r1
docker tag massopencloud/horizon-onboarding:r1 massopencloud/horizon-onboarding:r1-amd64
docker build . --build-arg IMAGE=ppc64le/fedora:30 -t massopencloud/horizon-onboarding:r1-ppc64le

cd .moc