require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    puts "Beg where"
    where_line = ''
    
    params.each_key do |key|
      key = key.to_s 
      where_line << key
      where_line << ' = ?'
      where_line.concat('AND ') unless key == params.keys.last.to_s
    end
    
    p where_line
    sql_call = <<-SQL
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        #{where_line}
    SQL
    
    result = DBConnection.execute(sql_call, params.values)
    parsed = self.parse_all(result)
    parsed
  end
end

class SQLObject
  # Mixin Searchable here...
  extend Searchable

end
