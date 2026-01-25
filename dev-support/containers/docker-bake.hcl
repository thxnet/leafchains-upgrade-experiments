variable "TAG" {
  default = "develop"
}

variable "CONTAINER_REGISTRY" {
  default = "ghcr.io/thxnet"
}

variable "DEBUG" {
  default = "0"
}

group "default" {
  targets = [
    "leafchain",
    "leafchain-genesis",
  ]
}

target "builder" {
  dockerfile = "dev-support/containers/debian/builder/Containerfile"
  target     = "builder"
  contexts = {
    ci-linux = "docker-image://docker.io/paritytech/ci-linux:production"
  }
  args = {
    DEBUG = "${DEBUG}"
  }
  platforms = ["linux/amd64"]
}

target "leafchain" {
  dockerfile = "dev-support/containers/debian/leafchain/Containerfile"
  target     = "leafchain"
  tags       = ["${CONTAINER_REGISTRY}/leafchain:${TAG}"]
  contexts = {
    builder = "target:builder"
    alpine  = "docker-image://docker.io/library/ubuntu:22.04"
  }
  labels = {
    "description"                     = "Container image for leafchains of THXNET."
    "io.thxnet.image.type"            = "final"
    "io.thxnet.image.authors"         = "contact@thxlab.io"
    "io.thxnet.image.vendor"          = "thxlab.io"
    "io.thxnet.image.description"     = "THXNET.: The Hybrid Next-Gen Blockchain Network"
    "org.opencontainers.image.source" = "https://github.com/thxnet/leafchains"
  }
  platforms = ["linux/amd64"]
}

target "leafchain-genesis" {
  dockerfile = "dev-support/containers/debian/leafchain-genesis/Containerfile"
  target     = "leafchain-genesis"
  tags       = ["${CONTAINER_REGISTRY}/leafchain-genesis:${TAG}"]
  contexts = {
    builder = "target:builder"
    alpine  = "docker-image://docker.io/alpine:3.18"
  }
  labels = {
    "description"                     = "Chain specifications and genesis file for leafchains of THXNET."
    "io.thxnet.image.type"            = "final"
    "io.thxnet.image.authors"         = "contact@thxlab.io"
    "io.thxnet.image.vendor"          = "thxlab.io"
    "io.thxnet.image.description"     = "Chain specifications and genesis file for leafchains of THXNET."
    "org.opencontainers.image.source" = "https://github.com/thxnet/leafchains"
  }
  platforms = ["linux/amd64"]
}
