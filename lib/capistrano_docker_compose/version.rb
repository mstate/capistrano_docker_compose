module CapistranoDockerCompose
  require 'yaml'

  class Version
    # def initialize
    #   @yaml = Version.yaml_file
    #   @current_version = (@yaml[:current_version] || "1.0.0")
    # end

    def self.increment!(options={})
      options[:type] ||= "incremental"
      hash_from_yaml_file = Version.yaml_file
      version_elements = hash_from_yaml_file[:current_version].split(/\./)
      # last_version_element = version_elements.shift
      case options[:type].to_s
        when "incremental"
          version_elements[2] = (version_elements[2].to_i + 1).to_s
        when "minor" # reset incremental to 0
          version_elements[1] = (version_elements[1].to_i + 1).to_s
          version_elements[2] = 0
        when "major" # reset minor and incremental to 0
          version_elements = [(version_elements[0].to_i + 1).to_s, 0, 0]

      end
      new_version = version_elements.join(".")
      hash_from_yaml_file[:current_version] = new_version
      hash_from_yaml_file[:release_history].unshift({version: new_version, released_at: Time.now})
      Version.update_yaml_file!(hash_from_yaml_file)
      return new_version
    end

    def self.current
      Version.yaml_file[:current_version]
    end

    def self.own_current
      original_project_root = @@project_root_folder
      @@project_root_folder = Dir.pwd
      my_version = self.current
      @@project_root_folder = original_project_root
      return my_version
    end

    def self.replace_version_constant_in_file!(current_version)
      yaml = YAML.load_file(Rails.root.join("config","version.yml"))
      File.write('/tmp/test.yml', d.to_yaml)
    end

    def self.yaml_file
      begin
        file = YAML.load_file([@@project_root_folder,"config","version.yml"].join('/'))
      rescue Errno::ENOENT => error
        version_hash = {
          current_version: "1.0.0",
          release_history: [
            {version: "1.0.0", released_at: Time.now}
          ]
        }
        # file doesn't exist.  create it
        Version.update_yaml_file!(version_hash)
        return version_hash
      end
    end

    def self.update_yaml_file!(version_hash)
      File.open([@@project_root_folder,"config","version.yml"].join('/'), 'w') do |f|
        f.write version_hash.to_yaml
      end
    end

    def self.root_fo

    end

    # initialization for class
    @@project_root_folder = if defined?(Rails)
      Rails.root
    else
      Dir.pwd
    end
    VERSION ||= self.own_current


  end
end
