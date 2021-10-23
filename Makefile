#!/usr/bin/make

IMAGE_NAME="oality/buildout-oality"

buildout.cfg:
	ln -fs dev.cfg buildout.cfg

bin/buildout: bin/pip buildout.cfg
	bin/pip install -r requirements.txt

buildout: bin/instance

bin/instance: bin/buildout
	bin/buildout

bin/pip:
	python3.8 -m venv .

run: bin/instance
	bin/instance fg

start: bin/instance
	bin/instance start

docker-image:
	docker build --pull -t oality/buildout-oality:latest .

eggs:  ## Copy eggs from docker image to speed up docker build
	-docker run --entrypoint='' $(IMAGE_NAME) tar -c -C /plone eggs | tar x
	mkdir -p eggs

cleanall:
	rm -fr develop-eggs downloads eggs parts .installed.cfg lib lib64 include bin .mr.developer.cfg local/

bash:
	docker-compose run --rm -p 8080:8080 -u plone instance bash

upgrade-steps:
	bin/instance -O Plone run scripts/run_portal_upgrades.py
