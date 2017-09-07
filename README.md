# Capistrano - Docker Compose Deployment from Git Cache

This gem allows you to easily deploy applications based on docker_compose.yml files.

First - add following file to your gemfile:

    gem 'capistrano_docker_compose', github: 'mstate/capistrano_docker_compose'

Next, add following to your `Capfile`:

    require 'capistrano/docker_compose'

The variables below are optional (and can be set in deploy.rb). Default values are listed.
    set :docker_app_service_name, "app"
    set :docker_web_service_name, "web"
    set :docker_database_service_name, "db"
    set :docker_app_dockerfile, "Dockerfile.prod"
    set :docker_web_dockerfile, "Dockerfile.prod.nginx"

    set :docker_compose_files, %w{docker-compose.yml docker-compose.prod.yml}
    set :registry, 'registry.modus-ops.com'
    set :docker_web_registry_link, "#{fetch(:registry)}/#{fetch(:application)}/web"
    set :docker_app_registry_link, "#{fetch(:registry)}/#{fetch(:application)}/app"
    set :branch, "asset_class_computation"
    set :git_cache_folder, "tmp/git_cache_for_deploy"
    set :docker_services_for_quick_restart, %w{ app actioncable sidekiq web }
    set :traefik_directory, "/docker/compose_files_and_data/traefik"

