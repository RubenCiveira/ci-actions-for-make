-include .ci/include/Makefile-common.mk .ci/include/Makefile-maven.mk .ci/include/Makefile-docker.mk .ci/include/Makefile-git.mk


SONAR_HOST_URL=http://localhost:9000
SONAR_TOKEN=sqa_67eedcbd6077003ee9f5ec37ca751ed930df554e

u_clean:
	mvn clean

u_test:
	@.ci/actions/actions.sh test
	# mvn clean verify -Pcoverage

u_verify:
	@.ci/actions/actions.sh verify

u_lint:
	@.ci/actions/actions.sh lint
	# mvn checkstyle:check

u_format:
	mvn formatter:format

u_quality:
	mvn clean verify org.sonarsource.scanner.maven:sonar-maven-plugin:3.9.1.2184:sonar -Dsonar.host.url=$(SONAR_HOST_URL) -Dsonar.token=$(SONAR_TOKEN)

docker-build:
	docker build --platform linux/arm64 --build-arg BUILDKIT_INLINE_CACHE=1 --progress=plain -f src/main/docker/Dockerfile.native-micro.multistage -t "registry.gitlab.com/phylax2/phylax-api:0.1.0-arm64" --push .

docker-run:
	docker run --env-file src/main/docker/env.local.docker -i --rm -p 8090:8090 -p 9002:9002 civi/phylax-api
	
docker-publish:
	docker buildx build --platform linux/amd64,linux/arm64 -f src/main/docker/Dockerfile.native-micro.multistage -t "civi/phylax-api:0.1.0" --push .

