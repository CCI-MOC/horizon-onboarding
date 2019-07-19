#!/bin/bash
docker push massopencloud/horizon-onboarding:r1
docker push massopencloud/horizon-onboarding:r1-amd64
docker push massopencloud/horizon-onboarding:r1-ppc64le

docker manifest create massopencloud/horizon-onboarding:r1 \
    massopencloud/horizon-onboarding:r1-amd64 \
    massopencloud/horizon-onboarding:r1-ppc64le --amend

docker manifest push massopencloud/horizon-onboarding:r1