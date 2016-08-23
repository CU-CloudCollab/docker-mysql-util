require 'mysql2'

SCHEMA_EXCLUSIONS = ['information_schema', 'innodb', 'mysql', 'performance_schema', 'sys', 'test', 'tmp']

# Get the list of MyISAM tables in the given target schema.
def get_myisam_tables(mysql2_client)

  target_schemas = SCHEMA_EXCLUSIONS.map { |x| "'#{x}'" }
  schema_list = target_schemas.join(", ")
  query = "SELECT TABLE_SCHEMA, TABLE_NAME, ENGINE " \
            " FROM INFORMATION_SCHEMA.TABLES " \
            " WHERE ENGINE = 'MyISAM' "  \
            " AND TABLE_SCHEMA NOT IN (#{schema_list}) "

  # puts "SQL: #{query}"
  results = mysql2_client.query(query)
  tables = []
  results.each { |row|
  #  puts "#{row['TABLE_SCHEMA']} #{row['TABLE_NAME']} #{row['ENGINE']}"
    tables << "`#{row['TABLE_SCHEMA']}`.`#{row['TABLE_NAME']}`"
  }
  # puts "TABLES: #{tables}"
  return tables
end

###############################
# FLUSH & LOCK TABLES
###############################
def flush_and_lock_tables(mysql2_client, tables)

  query = "FLUSH TABLES " + tables.join(", ") + " WITH READ LOCK"
  # puts "QUERY: #{query}"
  # This statement does not return a result set
  mysql2_client.query(query)

end

###############################
# UNLOCK TABLES
###############################
def unlock_tables(mysql2_client)

  # This statement does not return a result set
  mysql2_client.query("UNLOCK TABLES")

end

###############################
# Get the number of tables that this session has locked.
###############################
def get_number_locked_tables(mysql2_client)

  mysql2_client.query("SHOW OPEN TABLES WHERE IN_USE > 0").count

end

###############################
# Get a mysql connection
###############################
def get_mysql2_client(host, username, password, database = "mysql")

  return Mysql2::Client.new(
    :host => host,
    :username => username,
    :password => password,
    :database => database
    # :socket = '/path/to/mysql.sock',
    # :flags = REMEMBER_OPTIONS | LONG_PASSWORD | LONG_FLAG | TRANSACTIONS | PROTOCOL_41 | SECURE_CONNECTION | MULTI_STATEMENTS,
    # :encoding = 'utf8',
    # :read_timeout = seconds,
    # :write_timeout = seconds,
    # :connect_timeout = seconds,
    # :reconnect = true/false,
    # :local_infile = true/false,
    # :secure_auth = true/false,
    # :default_file = '/path/to/my.cfg',
    # :default_group = 'my.cfg section',
    # :init_command => sql
    )

end
