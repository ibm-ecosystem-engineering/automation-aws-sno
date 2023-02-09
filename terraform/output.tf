output "username" {
  value = module.cluster.username
  description = "Username for cluster"
}

output "serverURL" {
  value = module.cluster.serverURL
  description = "API URL for CLI login"
}

output "password" {
  value = module.cluster.password
  sensitive = true
  description = "Cluster password"
}

output "consoleURL" {
  value = module.cluster.consoleURL
  description = "Web browser URL for console"
}