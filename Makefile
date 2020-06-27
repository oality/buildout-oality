#!/usr/bin/make

IMAGE_NAME="docker-staging.imio.be/library/mutual:latest"
MID=couvin

buildout.cfg:
	ln -fs dev.cfg buildout.cfg

bin/buildout: bin/pip buildout.cfg
	bin/pip install -I -r requirements.txt

buildout: bin/instance

bin/instance: bin/buildout
	bin/buildout

bin/pip:
	virtualenv -p python3 .

run: bin/instance
	bin/instance fg

docker-image:
	docker build --pull -t library/mutual:latest .

eggs:  ## Copy eggs from docker image to speed up docker build
	-docker run --entrypoint='' $(IMAGE_NAME) tar -c -C /plone eggs | tar x
	mkdir -p eggs

cleanall:
	rm -fr develop-eggs downloads eggs parts .installed.cfg lib lib64 include bin .mr.developer.cfg local/

rsync:
	rsync -P imio@bibliotheca.imio.be:/srv/instances/$(MID)/filestorage/Data.fs var/filestorage/Data.fs
	rsync -r --info=progress2 imio@bibliotheca.imio.be:/srv/instances/$(MID)/blobstorage/ var/blobstorage/

bash:
	docker-compose run --rm -p 8080:8080 -u imio instance bash

chown-docker-dev:
	sudo chown 913:209 -R var

chown-local-dev:
	sudo chown $(USER):$(USER) -R src/plone.app.contenttypes
	sudo chown $(USER):$(USER) -R src/plone.outputfilters
	sudo chown $(USER):$(USER) -R var

upgrade-steps:
	bin/instance -O plone run scripts/run_portal_upgrades.py
