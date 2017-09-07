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

This gem also includes a CapistranoDockerCompose::Version class that tracks the current version of the application in config/version.yml as well as release history.

The version is in the form: major.minor.incremental

and also the following class methods:

    `CapistranoDockerCompose::Version.current`    - Current version
    `CapistranoDockerCompose::Version.increment!` - Increases the incremental version

The `increment!` method also provides an optional argument type:

    CapistranoDockerCompose::Version.increment!(type: :major) - E.g. 1.2.3 -> 2.0.0
    CapistranoDockerCompose::Version.increment!(type: :minor) - E.g. 1.2.3 -> 1.3.0
    CapistranoDockerCompose::Version.increment!(type: :incremental) - (This is the default) E.g. 1.2.13 -> 1.2.14

CapistranoDockerCompose::Version offers the following rake tasks:

    `rake version:increment`
    `rake version:current` (or just `rake version`)

`version:increment` accepts optional arguments for version type:

    `rake version:increment["major"]`

NB: The version of the app is used when tagging, pushing and deploying images to production.  For now, incrementing is a manual process.

