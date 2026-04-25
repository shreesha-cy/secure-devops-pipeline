package main

deny[msg] {
  container := input.spec.containers[_]
  not container.resources.limits.cpu
  msg = "CPU limit missing"
}

deny[msg] {
  container := input.spec.containers[_]
  not container.resources.limits.memory
  msg = "Memory limit missing"
}
