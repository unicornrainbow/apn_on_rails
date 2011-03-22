require 'rails/generators/active_record'

module ApnOnRails
  module Generators
    class MigrationsGenerator < Rails::Generators::Base
      include Rails::Generators::Migration
      extend ActiveRecord::Generators::Migration
      
      # Set the current directory as base for the inherited generators.
      def self.base_root
        File.dirname(__FILE__)
      end
      
      source_root File.expand_path('../templates/migrations', __FILE__)
  
      def create_migrations
        # Dir.glob(File.join(self.class.base_root, 'templates', 'migrations', '*.rb')).sort.each do |file|          
        #   migration_template("#{File.basename(file)}", "db/migrate/#{File.basename(file)}");
        # end
        
        migration_template('create_apn_devices.rb', 'db/migrate/create_apn_devices.rb')
        migration_template('create_apn_notifications.rb', 'db/migrate/create_apn_notifications.rb')
        migration_template('create_apn_apps.rb', 'db/migrate/create_apn_apps.rb')
        migration_template('alter_apn_devices.rb', 'db/migrate/alter_apn_devices.rb')
        migration_template('create_groups.rb', 'db/migrate/create_groups.rb')
        migration_template('alter_apn_groups.rb', 'db/migrate/alter_apn_groups.rb')
        migration_template('create_device_groups.rb', 'db/migrate/create_device_groups.rb')
        migration_template('create_apn_group_notifications.rb', 'db/migrate/create_apn_group_notifications.rb')
        migration_template('create_pull_notifications.rb', 'db/migrate/create_pull_notifications.rb')
        migration_template('alter_apn_notifications.rb', 'db/migrate/alter_apn_notifications.rb')
        migration_template('make_device_token_index_nonunique.rb', 'db/migrate/make_device_token_index_nonunique.rb')
        migration_template('add_launch_notification_to_apn_pull_notifications.rb', 'db/migrate/add_launch_notification_to_apn_pull_notifications.rb')
        
      end
    end
  end
end

