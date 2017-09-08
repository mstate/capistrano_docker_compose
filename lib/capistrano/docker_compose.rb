require_relative '../capistrano_docker_compose/version'
require_relative '../merge_docker_hash'
load File.expand_path("../tasks/docker_compose.rake", __FILE__)
