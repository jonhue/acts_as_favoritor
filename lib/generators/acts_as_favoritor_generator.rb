require 'rails/generators'
require 'rails/generators/migration'

class ActsAsFavoritorGenerator < Rails::Generators::Base

    include Rails::Generators::Migration

    source_root File.join File.dirname(__FILE__), 'templates'
    desc 'Install acts_as_favoritor'
    class_option :scope, desc: 'Specify your default scope. Learn more about scopes here: https://github.com/slooob/acts_as_favoritor#scopes', type: :string, default: 'favorite', aliases: '-s'
    class_option :skip_configuration, desc: 'Skip the creation of the configuration file. Learn more about configuring acts_as_favoritor here: https://github.com/slooob/acts_as_favoritor#configuration', type: :boolean, default: false

    def self.next_migration_number dirname
        if ActiveRecord::Base.timestamped_migrations
            Time.now.utc.strftime '%Y%m%d%H%M%S'
        else
            "%.3d" % (current_migration_number(dirname) + 1)
        end
    end

    def create_migration_file
        migration_template 'migration.rb.erb', 'db/migrate/acts_as_favoritor_migration.rb', migration_version: migration_version
    end

    def create_model
        template 'model.rb', 'app/models/favorite.rb'
    end

    def create_configuration
        template 'acts_as_favoritor.yml.erb', 'config/acts_as_favoritor.yml' unless options[:skip_configuration]
    end

    def show_readme
        readme 'README.md'
    end

end
