require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    return @column_names if @column_names
    cols = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        "#{self.table_name}"
    SQL
    @column_names = cols.first.map {|col| col.to_sym }
  end

  def self.finalize!
    self.columns.each do |col_name|
      define_method(col_name) do 
        self.attributes[col_name]
      end
      define_method("#{col_name}=") do |val|
        self.attributes[col_name] = val
      end  
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name||= "#{self.name.downcase}s"
  end

  def self.all
    results = DBConnection.execute(<<-SQL)
      SELECT
        #{table_name}.*      
      FROM
        "#{table_name}"
    SQL

    parse_all(results)
  end

  def self.parse_all(results)
    results.map {|result| self.new(result) }
  end

  def self.find(id)
    # return nil? if id.nil?
    results = DBConnection.execute(<<-SQL, id)
      SELECT
        #{table_name}.*
      FROM
        #{table_name}
      WHERE
        #{table_name}.id = ?
    SQL

    parse_all(results).first
  end

  def initialize(params = {})
    params.each do |param, param_value|
      attr_name = param.to_sym
      if self.class.columns.include?(attr_name)
        self.send("#{attr_name}=", param_value)
      else
        raise "unknown attribute '#{param}'"
      end
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
      self.attributes.values
  end

  def insert
    DBConnection.execute(<<-SQL, "#{attribute_values}")
      INSERT INTO
       #{table_name}
      VALUES
        #{attribute_values}

    SQL
  end

  def update
    line = self.class.columns.map { |attrib| "#{attrib} = ?"}
      .join(", ")

    DBConnection.execute(<<-SQL , *attribute_values, id)
      UPDATE

      
    SQL
  end

  def save
    id.nil? ? insert : update
  end
end
