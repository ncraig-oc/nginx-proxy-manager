#!/bin/bash

echo "building frontend"
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 413067109875.dkr.ecr.us-east-1.amazonaws.com

./scripts/ci/frontend-build
read -n 1 -p "Press any key"
echo "building backend"
echo 'Checking Syntax ...'

IMAGE="owenscorning/aws-nginx-full"
DOCKER_IMAGE="413067109875.dkr.ecr.us-east-1.amazonaws.com/${IMAGE}:certbot-node"
FINISH_IMAGE="413067109875.dkr.ecr.us-east-1.amazonaws.com/${IMAGE}:fargate"
BUILD_VERSION=`cat .version`
MAJOR_VERSION="2"
BRANCH_LOWER="master"

aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 413067109875.dkr.ecr.us-east-1.amazonaws.com

docker pull ${DOCKER_IMAGE}
docker run --rm \
	-v "$(pwd)/backend:/app" \
	-v "$(pwd)/global:/app/global" \
	-w /app \
	"${DOCKER_IMAGE}" \
	sh -c "yarn install && yarn eslint . && rm -rf node_modules"
echo "-----------------"
echo 'Docker Build ...'
docker build --pull --no-cache --squash --compress \
	-t "${IMAGE}:fargate" \
	-f docker/Dockerfile \
	--build-arg TARGETPLATFORM=linux/amd64 \
	--build-arg BUILDPLATFORM=linux/amd64 \
	--build-arg BUILD_VERSION="${BUILD_VERSION}" \
	--build-arg BUILD_DATE="$(date '+%Y-%m-%d %T %Z')" \
	.

docker run -it  -p 8080:80 -p 8081:81 -v /mnt/c/Projects/nginx-proxy-manager/rootfolder:/data --name data  "${FINISH_IMAGE}"