# MySQL helper functions using the mysql2 gem directly.
# Does not use any ActiveRecord infrastructure.

require 'mysql2'

# The list of schemas/databases should be excluded from MyISAM table locks.
# These are the schemas/databases used by RDS/MySQL, but they do contain some
# MyISAM tables.
SCHEMA_EXCLUSIONS = %w(information_schema innodb mysql performance_schema sys).freeze

# Get the list of MyISAM tables in the given target schema.
# @param mysql2_client [Mysql2::Client] initialized mysql2 client connection
# @return [Array<String>] List of full qualified table names
#   (i.e., \`schemaname\`.\`tablename\`) using the MyISAM engine.
#
def get_myisam_tables(mysql2_client)
  target_schemas = SCHEMA_EXCLUSIONS.map { |x| "'#{x}'" }
  schema_list = target_schemas.join(', ')
  query = 'SELECT TABLE_SCHEMA, TABLE_NAME, ENGINE ' \
          ' FROM INFORMATION_SCHEMA.TABLES ' \
          ' WHERE ENGINE = \'MyISAM\' '  \
          " AND TABLE_SCHEMA NOT IN (#{schema_list}) "

  # puts "SQL: #{query}"
  results = mysql2_client.query(query)
  tables = []
  results.each do |row|
    tables << "`#{row['TABLE_SCHEMA']}`.`#{row['TABLE_NAME']}`"
  end
  tables
end

# Execute "FLUSH TABLES ... WITH READ LOCK" on the MyISAM tables
# frmo {#get_myisam_tables}.
# @param mysql2_client [Mysql2::Client] initialized mysql2 client connection
# @param [Array<String>] List of full qualified table names
#
def flush_and_lock_tables(mysql2_client, tables)
  # This statement does not return a result set
  mysql2_client.query('FLUSH TABLES ' + tables.join(', ') + ' WITH READ LOCK')
end

# Unlock all locked tables.
# @param mysql2_client [Mysql2::Client] initialized mysql2 client connection
#
def unlock_tables(mysql2_client)
  # This statement does not return a result set
  mysql2_client.query('UNLOCK TABLES')
end

# Get the number of tables that this MySQL session has locked.
# @param mysql2_client [Mysql2::Client] initialized mysql2 client connection
# @return [Integer] the number of tables currently locked
#
def get_number_locked_tables(mysql2_client)
  mysql2_client.query('SHOW OPEN TABLES WHERE IN_USE > 0').count
end

# Get a MySQL connection
# @param host [String]
# @param username [String]
# @param password [String]
# @param database [String]
# @return [Mysql2::Client] initialized mysql2 client connection
#
def get_mysql2_client(host, username, password, database = 'mysql')
  Mysql2::Client.new(
    host: host,
    username: username,
    password: password,
    database: database
    # :socket = '/path/to/mysql.sock',
    # :flags = REMEMBER_OPTIONS | LONG_PASSWORD | LONG_FLAG | TRANSACTIONS \
    #          | PROTOCOL_41 | SECURE_CONNECTION | MULTI_STATEMENTS,
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
