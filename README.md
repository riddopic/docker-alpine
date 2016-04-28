
# [<img src=".bluebeluga.png" height="100" width="200" style="border-radius: 50%;" alt="@fancyremarker" />](https://github.com/riddopic/docker-alpine) bluebeluga/alpine

[![Circle CI](http://circle.bluebeluga.io/gh/riddopic/docker-alpine.svg?style=svg)](http://circle.bluebeluga.io/gh/riddopic/docker-alpine)

Alpine Linux base image for Docker.

## Installation and Usage

```
docker pull bluebeluga/alpine
docker run bluebeluga/alpine [options]
```

## Available Tags

* `latest`: Currently 3.3
* `3.2`:
* `3.3`:
* `edge`:


## Tests

Tests are run as part of the `Makefile` build process. To execute them run the following command:

```
make test
```

## Deployment

To push the Docker image to the registry, run the following command:

```
make push
```
