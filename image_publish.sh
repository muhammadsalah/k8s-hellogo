#!/usr/bin/env bash

docker build -t ${IMAGE_REGISTRY}/${SERVICE_NAME}:${GO_PIPELINE_LABEL} .

docker push ${IMAGE_REGISTRY}/${SERVICE_NAME}:${GO_PIPELINE_LABEL}

