#!/usr/bin/env ruby

require 'cucloud'
require_relative 'mysql_util'

# required
db_host = ENV['DB_HOST']
db_user = ENV['DB_USER']
db_password = ENV['DB_PASSWORD']
rds_id = ENV['DB_RDS_ID']

# optional
creator_tag = ENV['CREATOR_TAG']
application_tag = ENV['APPLICATION_TAG']
environement_tag = ENV['ENVIRONMENT_TAG']

if db_host.nil? || db_user.nil? || db_password.nil? || rds_id.nil?
  abort('Expecting the following environment variables to be set: ' \
        'DB_HOST, DB_USER, DB_PASSWORD, DB_RDS_ID')
end

mysql2_client = get_mysql2_client(db_host, db_user, db_password)

tables = get_myisam_tables(mysql2_client)
puts "Number of target MyISAM tables: #{tables.size}"

puts 'Locking tables.'
flush_and_lock_tables(mysql2_client, tables)

puts 'Creating snapshot, and waiting for completion.'
rds_utils = Cucloud::RdsUtils.new
rds_instance = rds_utils.get_instance(rds_id)

# Add tags if values are present
tags = []
tags << { key: 'Creator', value: creator_tag } unless creator_tag.nil?
tags << { key: 'Application', value: application_tag } unless application_tag.nil?
tags << { key: 'Environment', value: environement_tag } unless environement_tag.nil?

snap = rds_utils.create_snapshot_and_wait_until_available(rds_instance, tags)

puts 'Unlocking tables.'
unlock_tables(mysql2_client)

mysql2_client.close

abort('Unable to create snapshot.') if snap.nil?

exit
