#!/bin/bash

docker_build() {
	# si no hay multistage => primero tenemos que compilar
	local target_platform=$(get_platform)
	local target_version=$(get_version)
	local target_name=$(get_name)

	echo "- Build docker ${CONTAINER_REPOSITORY}/${CONTAINER_REPOSITORY_PATH}/${target_name}:${target_version}-${target_platform}"

    docker login -u "$CONTAINER_REPOSITORY_USER" -p "$CONTAINER_REPOSITORY_PASS" "$CONTAINER_REPOSITORY"

	docker build --platform linux/${target_platform} \
		--build-arg BUILDKIT_INLINE_CACHE=1 --progress=plain \
		-f "${CONTAINER_FILE}" \
		-t "${CONTAINER_REPOSITORY}/${CONTAINER_REPOSITORY_PATH}/${target_name}:${target_version}-${target_platform}" \
		--push .
}

docker_multiplatform() {
	local target_platform=$(get_platform)
	local target_version=$(get_version)
	local target_name=$(get_name)

	docker buildx imagetools create --tag "${CONTAINER_REPOSITORY}/${CONTAINER_REPOSITORY_PATH}/${target_name}:${target_version}" \
  		"${CONTAINER_REPOSITORY}/${CONTAINER_REPOSITORY_PATH}/${target_name}:${target_version}-amd64" \
  		"${CONTAINER_REPOSITORY}/${CONTAINER_REPOSITORY_PATH}/${target_name}:${target_version}-arm64"
}