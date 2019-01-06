#!/usr/bin/env bash

if [ -z $KUBE_TOKEN ]; then
  echo "FATAL: Environment Variable KUBE_TOKEN must be specified."
  exit ${2:-1}
fi

if [ -z $NAMESPACE ]; then
  echo "FATAL: Environment Variable NAMESPACE must be specified."
  exit ${2:-1}
fi

if [ -z $SERVICE_NAME ]; then
  echo "FATAL: Environment Variable SERVICE_NAME must be specified."
  exit ${2:-1}
fi

echo
echo "Namespace $NAMESPACE"

echo
echo "Service: $SERVICE_NAME"

status_code=$(curl -sSk -H "Authorization: Bearer $KUBE_TOKEN" \
    "https://kubernetes.default.svc.cluster.local:$KUBERNETES_PORT_443_TCP_PORT/apis/apps/v1/namespaces/$NAMESPACE/deployments/$SERVICE_NAME" \
    -X GET -o /dev/null -w "%{http_code}")


cp deployment.json todeploy.json

sed -i "s@CHANGEIMAGE@${IMAGE_REGISTRY}/${NAMESPACE}/${SERVICE_NAME}:${GO_PIPELINE_LABEL}@g" todeploy.json
sed -i "s@CHANGEVERSION@v-dev-${GO_PIPELINE_LABEL}@g" todeploy.json

if [ $status_code == 200 ]; then
  echo
  echo "Updating deployment"
  curl -H 'Content-Type: application/strategic-merge-patch+json' -sSk -H "Authorization: Bearer $KUBE_TOKEN" \
    "https://kubernetes.default.svc.cluster.local:$KUBERNETES_PORT_443_TCP_PORT/apis/apps/v1/namespaces/$NAMESPACE/deployments/$SERVICE_NAME" \
    -X PATCH -d @todeploy.json
else
 echo
 echo "Creating deployment"
 curl -H 'Content-Type: application/json' -sSk -H "Authorization: Bearer $KUBE_TOKEN" \
    "https://kubernetes.default.svc.cluster.local:$KUBERNETES_PORT_443_TCP_PORT/apis/apps/v1/namespaces/$NAMESPACE/deployments" \
    -X POST -d @todeploy.json
fi

status_code=$(curl -sSk -H "Authorization: Bearer $KUBE_TOKEN" \
    "https://kubernetes.default.svc.cluster.local:$KUBERNETES_PORT_443_TCP_PORT/api/v1/namespaces/$NAMESPACE/services/$SERVICE_NAME" \
    -X GET -o /dev/null -w "%{http_code}")

if [ $status_code == 404 ]; then
 echo
 echo "Creating service"
 curl -H 'Content-Type: application/json' -sSk -H "Authorization: Bearer $KUBE_TOKEN" \
    "https://kubernetes.default.svc.cluster.local:$KUBERNETES_PORT_443_TCP_PORT/api/v1/namespaces/$NAMESPACE/services" \
    -X POST -d @service.json
fi
