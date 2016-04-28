#!/usr/bin/env bats

setup() {
  docker history "bluebeluga/alpine:edge" >/dev/null 2>&1
}

@test "checking image size" {
  MAX_SIZE=20000
  run docker run "bluebeluga/alpine:edge" bash -c "[[ \"\$(du -d0 / 2>/dev/null | awk '{print \$1; print > \"/dev/stderr\"}')\" -lt \"$MAX_SIZE\" ]]"
  [ $status -eq 0 ]
}

@test "version is correct" {
  run docker run "bluebeluga/alpine:edge" cat /etc/os-release
  [ $status -eq 0 ]
  [ "${lines[2]}" = "VERSION_ID=3.3.0" ]
}

@test "package installs cleanly" {
  run docker run "bluebeluga/alpine:edge" apk add --update openssl
  [ $status -eq 0 ]
}

@test "timezone" {
  run docker run "bluebeluga/alpine:edge" date +%Z
  [ $status -eq 0 ]
  [ "$output" = "UTC" ]
}

@test "apk-install script should be installed" {
  run docker run "bluebeluga/alpine:edge" which apk-install
  [ $status -eq 0 ]
}

@test "repository list is correct" {
  run docker run "bluebeluga/alpine:edge" cat /etc/apk/repositories
  [ $status -eq 0 ]
  [ "${lines[0]}" = "http://dl-cdn.alpinelinux.org/alpine/edge/main" ]
  [ "${lines[1]}" = "http://dl-cdn.alpinelinux.org/alpine/edge/community" ]
  [ "${lines[2]}" = "" ]
}

@test "cache is empty" {
  run docker run "bluebeluga/alpine:edge" sh -c "ls -1 /var/cache/apk | wc -l"
  [ $status -eq 0 ]
  [ "$output" = "0" ]
}

@test "root password is disabled" {
  run docker run --user nobody "bluebeluga/alpine:edge" su
  [ $status -eq 1 ]
}
