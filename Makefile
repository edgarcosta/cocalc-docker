COCALC_DATA=/mnt/cocalc-data
COMMON_OPTIONS=--restart unless-stopped  --name=cocalc-docker --network no-inet -p 18.18.21.18:443:443 -p 18.18.21.18:80:80 --sysctl=net.ipv6.conf.all.disable_ipv6=1 -v $(COCALC_DATA)/projects:/projects  -v /opt/magma:/opt/magma:ro  -v /etc/letsencrypt/:/etc/letsencrypt/:ro --cap-add=NET_ADMIN -P
DOCKER_USER=edgarcosta
BRANCH=master
BUILD_DATE=$(shell date -u +'%Y-%m-%dT%H:%M:%SZ')
COMMIT=$(shell git ls-remote -h https://github.com/sagemathinc/cocalc $(BRANCH) | awk '{print $$1}')
COMMIT=f695624960 # Jan 11
#COMMIT=6e7d8fba49 # April 11
COMMIT=33fc0235b3 # Dec 25
COMMIT=c1c56ddbf00149079e729c155bd8af3e4e27872e # Dec 19
COMMIT=d26ab245e42d61cf7c3f332b264b5f87d1bde9ec # Nov 6
COMMIT=dce81ac # Nov 26
COMMIT=0ca12f9 # Dec 19
#COMMIT=a51c0315e4b4d85187643b735c221c90e60d7899 # Jun 24

# ARCH = '-x86_64' or '-arm64'
ARCH=$(shell uname -m | sed 's/x86_64/-x86_64/;s/arm64/-arm64/;s/aarch64/-arm64/')

# Update this for each new cocalc-docker release; it's a totally arbitrary version number.
TAG=dec19

SAGEMATH_TAG=10.5
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
	ln -s /etc/letsencrypt/live/diophantus.mit.edu/cert.pem $(COCALC_DATA)/projects/conf/cert/cert.pem
	ln -s /etc/letsencrypt/live/diophantus.mit.edu/privkey.pem $(COCALC_DATA)/projects/conf/cert/key.pem

################################################################################
# makefile debugging
# ################################################################################
print-%:
	@echo "$*=$($*)"
