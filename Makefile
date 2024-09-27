COCALC_DATA=/scratch/cocalc-data
COMMON_OPTIONS=-e COCALC_NO_IDLE_TIMEOUT=yes --name=cocalc-docker -p 443:443 --sysctl=net.ipv6.conf.all.disable_ipv6=1 -v /mnt/disks/mathml-data/data/:/data:ro -v $(COCALC_DATA)/projects:/projects  -v /opt/magma:/opt/magma:ro  -v /etc/letsencrypt/:/etc/letsencrypt/:ro --cap-add=NET_ADMIN -P
DOCKER_USER=edgarcosta
BRANCH=master
BUILD_DATE=$(shell date -u +'%Y-%m-%dT%H:%M:%SZ')
COMMIT=$(shell git ls-remote -h https://github.com/sagemathinc/cocalc $(BRANCH) | awk '{print $$1}')

# ARCH = '-x86_64' or '-arm64'
ARCH=$(shell uname -m | sed 's/x86_64/-x86_64/;s/arm64/-arm64/;s/aarch64/-arm64/')

# Update this for each new cocalc-docker release; it's a totally arbitrary version number.
TAG=1.5

SAGEMATH_TAG=10.4
cocalc-docker:
	docker build \
		--build-arg SAGEMATH_TAG=$(SAGEMATH_TAG) \
		--build-arg ARCH=$(ARCH) \
		--build-arg COMMIT=$(COMMIT) \
		--build-arg BRANCH=$(BRANCH) \
		--build-arg BUILD_DATE=$(BUILD_DATE) -t cocalc-docker$(ARCH) .
	docker tag cocalc-docker$(ARCH) $(DOCKER_USER)/cocalc-docker$(ARCH):$(TAG)

run-cocalc-docker:
	docker run $(COMMON_OPTIONS) $(DOCKER_USER)/cocalc-docker$(ARCH):$(TAG)

rm-cocalc-docker:
	docker stop cocalc-docker
	docker rm cocalc-docker

push-cocalc-docker:
	docker push $(DOCKER_USER)/cocalc-docker$(ARCH):$(TAG)

assemble-cocalc-docker:
	#./multiarch.sh $(DOCKER_USER)/cocalc-docker $(TAG)
	./multiarch.sh $(DOCKER_USER)/cocalc-docker $(TAG) latest
	./multiarch.sh $(DOCKER_USER)/cocalc-docker $(TAG) $(TAG)

cocalc-core:
	cd src && docker build --build-arg commit=$(COMMIT) --build-arg BRANCH=$(BRANCH) --build-arg BUILD_DATE=$(BUILD_DATE) -t cocalc-core$(ARCH) . -f cocalc-core/Dockerfile
	docker tag cocalc-core$(ARCH) $(DOCKER_USER)/cocalc-core:$(COMMIT)

assemble-cocalc-core:
	./multiarch.sh $(DOCKER_USER)/cocalc-core $(COMMIT)

pytorch:
	cd src && docker build --build-arg commit=$(COMMIT) --build-arg BRANCH=$(BRANCH) --build-arg BUILD_DATE=$(BUILD_DATE) -t cocalc-docker-pytorch . -f pytorch/Dockerfile
	docker tag cocalc-docker-pytorch $(DOCKER_USER)/cocalc-docker-pytorch:$(TAG)

run-pytorch:
	docker run --name=cocalc-docker-pytorch -d -p 127.0.0.1:4043:443 cocalc-docker-pytorch

rm-pytorch:
	docker stop cocalc-docker-pytorch
	docker rm cocalc-docker-pytorch

push-pytorch:
	docker push $(DOCKER_USER)/cocalc-docker-pytorch:$(TAG)

ssl:
	mkdir -p $(COCALC_DATA)/projects/conf/cert/
	if [ -e $(COCALC_DATA)/projects/conf/cert/cert.pem ]; then rm $(COCALC_DATA)/projects/conf/cert/cert.pem; fi
	if [ -e $(COCALC_DATA)/projects/conf/cert/key.pem ]; then rm $(COCALC_DATA)/projects/conf/cert/key.pem; fi
	ln -s /etc/letsencrypt/live/mathml2024.org/cert.pem $(COCALC_DATA)/projects/conf/cert/cert.pem
	ln -s /etc/letsencrypt/live/mathml2024.org/privkey.pem $(COCALC_DATA)/projects/conf/cert/key.pem

################################################################################
# makefile debugging
# ################################################################################
print-%:
	@echo "$*=$($*)"
