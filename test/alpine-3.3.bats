#!/usr/bin/env bats

setup() {
  docker history "bluebeluga/alpine:3.3" >/dev/null 2>&1
  export IMG="$REGISTRY/$REPOSITORY:$TAG"
  export MAX_SIZE=200000
}

@test "checking image size" {
  run docker run $IMG bash -c "[[ \"\$(du -d0 / 2>/dev/null | awk '{print \$1; print > \"/dev/stderr\"}')\" -lt \"$MAX_SIZE\" ]]"
  [ $status -eq 0 ]
}

@test "version is correct" {
  run docker run $IMG cat /etc/os-release
  [ $status -eq 0 ]
  [ "${lines[2]}" = "VERSION_ID=3.3.3" ]
}

@test "package installs cleanly" {
  run docker run $IMG apk add --update openssl
  [ $status -eq 0 ]
}

@test "timezone" {
  run docker run $IMG date +%Z
  [ $status -eq 0 ]
  [ "$output" = "UTC" ]
}

@test "apk-install script should be installed" {
  run docker run $IMG which apk-install
  [ $status -eq 0 ]
}

@test "repository list is correct" {
  run docker run $IMG cat /etc/apk/repositories
  [ $status -eq 0 ]
  [ "${lines[0]}" = "http://dl-cdn.alpinelinux.org/alpine/v3.3/main" ]
  [ "${lines[1]}" = "http://dl-cdn.alpinelinux.org/alpine/v3.3/community" ]
  [ "${lines[2]}" = "" ]
}

@test "cache is empty" {
  run docker run $IMG sh -c "ls -1 /var/cache/apk | wc -l"
  [ $status -eq 0 ]
  [ "$output" = "0" ]
}

@test "root password is disabled" {
  run docker run --user nobody $IMG su
  [ $status -eq 1 ]
}
