#!/usr/bin/env ruby

require 'mysql2'
require_relative 'mysql-util'
require_relative 'rds-snap-util'

db_host = ENV["DB_HOST"]
db_user = ENV["DB_USER"]
db_password = ENV["DB_PASSWORD"]
rds_id = ENV["DB_RDS_ID"]

mysql2_client = get_mysql2_client(db_host, db_user, db_password)

tables = get_myisam_tables(mysql2_client)
puts "Number of target MyISAM tables: #{tables.size}"

puts "Locking tables."
flush_and_lock_tables(mysql2_client, tables)

n = get_number_locked_tables(mysql2_client)
if (n != tables.size) then
  unlock_tables (mysql2_client)
  mysql2_client.close
  abort ("Could not lock all MyISAM tables.")
end

puts "Creating snapshot."
snap = create_snapshot(rds_id)

puts "Unlocking tables."
unlock_tables (mysql2_client)

n = get_number_locked_tables(mysql2_client)

puts "Number of tables locked: #{n}"

mysql2_client.close

abort("Unable to create snapshot.") if (snap.nil?)

exit

