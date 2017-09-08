# load File.expand_path("../tasks/version.rake", __FILE__)
require "capistrano_docker_compose/version"
require "capistrano_docker_compose/railtie" if defined?(Rails)
require_relative 'merge_docker_hash'

module CapistranoDockerCompose
end
