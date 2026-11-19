# docker-frankenphp

> [!IMPORTANT]
> **Temporary image.** It only exists to ship PHP versions that the official
> [`dunglas/frankenphp`](https://hub.docker.com/r/dunglas/frankenphp) image has not published yet.
> **If the same tag exists on `dunglas/frankenphp`, use the official image instead**
> (for example `dunglas/frankenphp:1.13.5-php8.5.13-alpine` once it is out).
> This repo builds from the same upstream Dockerfile, but it is not an official FrankenPHP release
> and it gets no updates once upstream catches up.

FrankenPHP **1.13.5** on PHP **8.5.13** (**Alpine**), published on Docker Hub.

Upstream `dunglas/frankenphp` stops at `1.13.5-php8.5.12-alpine`. PHP 8.5.13 (security release, 2026-11-19)
is already out as `php:8.5.13-zts-alpine`, so this repo builds the image the same way upstream does:

- the **upstream `alpine.Dockerfile`** from `php/frankenphp` tag `v1.13.5` (pinned commit in `versions.env`), unchanged;
- the same build contexts as upstream `docker-bake.hcl`: `php-base = php:8.5.13-zts-alpine`, `golang-base = golang:1.27-alpine`;
- the `runner` target, so the result matches `dunglas/frankenphp:1.13.5-php8.5.12-alpine` except for the PHP version.

`OS=trixie` (or `bookworm`) in `versions.env` builds the Debian variant from the upstream `Dockerfile` instead.

## Tags

| Tag | Content |
|-----|---------|
| `<user>/frankenphp:1.13.5-php8.5.13` | Debian trixie base, same as upstream `1.13.5-php8.5.12` (`make build OS=trixie`) |
| `<user>/frankenphp:1.13.5-php8.5.13-trixie` | Same image, explicit OS tag |
| `<user>/frankenphp:1.13.5-php8.5.13-alpine` | Base image, same as upstream alpine |
| `<user>/frankenphp:1.13.5-php8.5.13-alpine-symfony` | Base + apcu, bcmath, gd, intl, opcache, pdo_mysql, pdo_pgsql, redis, zip + Composer 2 |

## Usage

```bash
make help
make build DOCKERHUB_USER=myname     # local platform
make test  DOCKERHUB_USER=myname
make push  DOCKERHUB_USER=myname     # or: make push-multiarch (amd64 + arm64)
```

Set `DOCKERHUB_USER` once in `versions.env` to skip the argument.

## CI (GitHub Actions)

[`.github/workflows/build.yml`](.github/workflows/build.yml):

- pull requests and `main`: `make build test` on amd64, nothing is pushed;
- tags `v*` and manual runs (**Actions → build → Run workflow**): build on native `amd64` and `arm64` runners,
  push by digest and merge into the multi-arch tags above.

Repository settings needed (owner adds them, never in code):

- **Settings → Secrets and variables → Actions → Variables**: `DOCKERHUB_USER` = `nowotech`;
- **Secrets**: `DOCKERHUB_TOKEN` = a Docker Hub token with **Read & Write**.

Release: `git tag v1.13.5-php8.5.13 && git push origin v1.13.5-php8.5.13`.

## Updating versions

Edit `versions.env` (`FRANKENPHP_VERSION`, `FRANKENPHP_COMMIT`, `PHP_VERSION`), then `make clean build test`.
When upstream publishes `dunglas/frankenphp:1.13.5-php8.5.13-alpine` you can switch projects back to it.

Publishing guide: [docs/DOCKER_HUB_PUBLISHING.md](docs/DOCKER_HUB_PUBLISHING.md).
