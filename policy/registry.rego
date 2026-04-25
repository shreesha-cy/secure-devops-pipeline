package main

approved = ["docker.io", "ghcr.io"]

deny[msg] {
  image := input.spec.containers[_].image

  not allowed_registry(image)

  msg = sprintf("Unapproved registry: %s", [image])
}

allowed_registry(image) {
  some i
  startswith(image, approved[i])
}
