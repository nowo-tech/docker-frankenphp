# syntax=docker/dockerfile:1
# Symfony-ready variant on top of the base image built from upstream FrankenPHP.
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

RUN set -eux; \
	install-php-extensions \
		apcu \
		bcmath \
		gd \
		intl \
		opcache \
		pdo_mysql \
		pdo_pgsql \
		redis \
		zip \
	; \
	php -m

COPY --from=composer/composer:2-bin /composer /usr/bin/composer

ENV COMPOSER_ALLOW_SUPERUSER=1

LABEL org.opencontainers.image.description="FrankenPHP with common Symfony extensions and Composer"
LABEL org.opencontainers.image.source=https://github.com/nowo-tech/docker-frankenphp
