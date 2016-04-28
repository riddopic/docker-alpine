#!/usr/bin/env bats

setup() {
  docker history "bluebeluga/alpine:3.2" >/dev/null 2>&1
}

@test "checking image size" {
  MAX_SIZE=200000
  run docker run "bluebeluga/alpine:3.2" bash -c "[[ \"\$(du -d0 / 2>/dev/null | awk '{print \$1; print > \"/dev/stderr\"}')\" -lt \"$MAX_SIZE\" ]]"
  [ $status -eq 0 ]
}

@test "version is correct" {
  run docker run "bluebeluga/alpine:3.2" cat /etc/os-release
  [ $status -eq 0 ]
  [ "${lines[2]}" = "VERSION_ID=3.2.3" ]
}

@test "package installs cleanly" {
  run docker run "bluebeluga/alpine:3.2" apk add --update openssl
  [ $status -eq 0 ]
}

@test "timezone" {
  run docker run "bluebeluga/alpine:3.2" date +%Z
  [ $status -eq 0 ]
  [ "$output" = "UTC" ]
}

@test "apk-install script should be installed" {
  run docker run "bluebeluga/alpine:3.2" which apk-install
  [ $status -eq 0 ]
}

@test "repository list is correct" {
  run docker run "bluebeluga/alpine:3.2" cat /etc/apk/repositories
  [ $status -eq 0 ]
  [ "${lines[0]}" = "http://dl-cdn.alpinelinux.org/alpine/v3.2/main" ]
  [ "${lines[1]}" = "" ]
}

@test "cache is empty" {
  run docker run "bluebeluga/alpine:3.2" sh -c "ls -1 /var/cache/apk | wc -l"
  [ $status -eq 0 ]
  [ "$output" = "0" ]
}

@test "root password is disabled" {
  run docker run --user nobody "bluebeluga/alpine:3.2" su
  [ $status -eq 1 ]
}
