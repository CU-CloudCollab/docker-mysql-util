#!/usr/bin/env ruby

require 'mysql2'
require_relative 'mysql-util'
require_relative 'rds-snap-util'

db_host = ENV["DB_HOST"]
db_user = ENV["DB_USER"]
db_password = ENV["DB_PASSWORD"]
rds_id = ENV["DB_RDS_ID"]

if (db_host.nil? || db_user.nil? || db_password.nil? || rds_id.nil?) then
  abort("Expecting the following environment variables to be set: " \
        "DB_HOST, DB_USER, DB_PASSWORD, DB_RDS_ID")
end

mysql2_client = get_mysql2_client(db_host, db_user, db_password)

tables = get_myisam_tables(mysql2_client)
puts "Number of target MyISAM tables: #{tables.size}"

puts "Locking tables."
flush_and_lock_tables(mysql2_client, tables)

n = get_number_locked_tables(mysql2_client)

snap = create_snapshot(rds_id)

puts "Unlocking tables."
unlock_tables (mysql2_client)

mysql2_client.close

abort("Unable to create snapshot.") if (snap.nil?)

exit

