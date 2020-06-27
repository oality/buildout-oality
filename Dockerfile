FROM python:alpine as builder
ENV PIP=9.0.3 \
  ZC_BUILDOUT=2.13.2 \
  SETUPTOOLS=41.0.1 \
  WHEEL=0.31.1 \
  PLONE_MAJOR=5.2 \
  PLONE_VERSION=5.2.1

RUN addgroup -g 1000 plone \
 && adduser -S -D -G plone -u 1000 plone \
 && mkdir -p /plone /data/filestorage /data/blobstorage

RUN apk add --update --no-cache --virtual .build-deps \
  build-base \
  gcc \
  git \
  libc-dev \
  libffi-dev \
  libjpeg-turbo-dev \
  libpng-dev \
  libwebp-dev \
  libxml2-dev \
  libxslt-dev \
  openssl-dev \
  pcre-dev \
  tzdata \
  wget \
  zlib-dev \
  && pip install pip==$PIP setuptools==$SETUPTOOLS zc.buildout==$ZC_BUILDOUT wheel==$WHEEL \
  && ln -sf /usr/share/zoneinfo/Europe/Brussels /etc/localtime \
  && echo "Europe/Brussels" > /etc/timezone


WORKDIR /plone
RUN chown plone:plone -R /plone && chown plone:plone -R /data
# COPY --chown=plone eggs /plone/eggs/
COPY --chown=plone *.cfg /plone/
COPY --chown=plone scripts /plone/scripts
RUN su -c "buildout -c prod.cfg -t 30 -N" -s /bin/sh plone


FROM python:alpine

ENV PIP=9.0.3 \
  ZC_BUILDOUT=2.13.2 \
  SETUPTOOLS=41.0.1 \
  WHEEL=0.31.1 \
  PLONE_VERSION=5.2.1 \
  TZ=Europe/Brussel \
  ZEO_HOST=zeo \
  ZEO_PORT=8100 \
  HOSTNAME_HOST=local \
  PROJECT_ID=library

RUN addgroup -g 1000 plone \
 && adduser -S -D -G plone -u 1000 plone \
 && mkdir -p /plone /data/filestorage /data/blobstorage \
 && chown plone:plone -R /plone \
 && chown plone:plone -R /data


VOLUME /data/blobstorage
VOLUME /data/filestorage
WORKDIR /plone

RUN apk add --no-cache --virtual .run-deps \
  bash \
  rsync \
  libxml2 \
  libxslt \
  libpng \
  libjpeg-turbo \
  lynx \
  poppler-utils \
  wv

LABEL plone=$PLONE_VERSION \
  os="alpine" \
  os.version="3.10" \
  name="Plone 5.2.1" \
  description="Plone image for oality backend website" \
  maintainer="Benoît Suttor"

COPY --from=builder /usr/local/lib/python3.8/site-packages /usr/local/lib/python3.8/site-packages
COPY --chown=plone --from=builder /plone .
RUN chown plone:plone /plone

COPY --chown=plone docker-initialize.py docker-entrypoint.sh /
USER plone
EXPOSE 8080
HEALTHCHECK --interval=1m --timeout=5s --start-period=30s \
  CMD nc -z -w5 127.0.0.1 8080 || exit 1

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["console"]
