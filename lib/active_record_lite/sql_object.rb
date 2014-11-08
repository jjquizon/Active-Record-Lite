require_relative 'db_connection'
require 'active_support/inflector'
#NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
#    of this project. It was only a warm up.

class SQLObject
  
  def self.columns
    if @columns.nil?
      query = <<-SQL
        SELECT
          *
        FROM
          #{self.table_name}
      SQL
      columns = DBConnection.execute2(query)
      @columns = columns.first.map { |col| col.to_sym }
    end
    @columns
  end

  def self.finalize!
    columns.each do |col|
      define_method "#{col}=" do |item|
        attributes[col] = item
      end
      define_method "#{col}" do
        attributes[col]
      end
    end
  end

  def self.table_name=(table_name)
    @table_name =  table_name

  end

  def self.table_name
    @table_name = self.to_s.tableize if @table_name.nil?
    @table_name
  end

  def self.all
    table = <<-SQL
      SELECT
        *
      FROM
        #{table_name}
    
    SQL
    results = DBConnection.execute(table)
    self.parse_all(results)
    
  end

  def self.parse_all(results)
    results.map { |result| self.new(result) }
  end

  def self.find(id)
    table = <<-SQL
      SELECT
        *
      FROM
        #{table_name}
      WHERE
        id = ?
    
    SQL
    results = DBConnection.execute(table, id)
    parsed = self.parse_all(results)
    parsed.first
  end

  def attributes
    @attributes ||= {}  
    
  end

  def insert
    table_name = self.class.table_name
    cols = self.class.columns
    col_text = cols.join(', ')
    col_length = cols.length
    inject_str = "?, " * (col_length-1) + "?"
    
    sql_call = <<-SQL
    INSERT INTO
      #{table_name} (#{col_text})
    VALUES
      (#{inject_str})
    SQL
    
    DBConnection.execute(sql_call, *attribute_values)
    attributes[:id] = DBConnection.last_insert_row_id
  end

  def initialize(hash = nil)
    unless hash.nil?
      table_col = self.class.columns
      hash.each do |hash_key, hash_value|
        hash_sym = hash_key.to_sym
      
        unless table_col.include?(hash_sym)
          raise Exception.new("unknown attribute '#{hash_key}'")
        end 
      
        attributes[hash_sym] = hash_value
      end
    end
  end

  def save
    if attributes[:id].nil?
      self.insert
    else
      self.update
    end
  end

  def build_string
    string = ''
    self.class.columns.each do |column| 
      string.concat("#{column} = ?")
      string.concat(", ") unless column == self.class.columns.last
    end
    string
  end
  
  def update
    table_name = self.class.table_name
    id = attributes[:id]
    string = build_string
    sql_call = <<-SQL
      UPDATE
        #{table_name}
      SET
        #{string}
      WHERE
        id = #{id}
    SQL
    
    DBConnection.execute(sql_call, *attribute_values)
  end

  def attribute_values
    self.class.columns.map { |column| self.send(column) }
  end
end
