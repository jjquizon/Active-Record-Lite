require_relative '02_searchable'
require 'active_support/inflector'

# Phase IVa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    @class_name.constantize
  end

  def table_name
    @table_name = @class_name.downcase.concat('s')
  end
end

class BelongsToOptions < AssocOptions
  # def initialize(name, options = {})
  #   fk = name.to_s.dup.concat("_id").to_sym
  #   if options.empty?  
  #     @class_name = name.to_s.camelcase
  #     @foreign_key = fk
  #     @primary_key = :id
  #   else 
  #     @class_name = options[:class_name]
  #     @foreign_key = options[:foreign_key]
  #     @primary_key = options[:primary_key].nil? ? :id : options[:primary_key]
  #   end
  # end
  
  def initialize(name, options = {})
    defaults = {
      :foreign_key => "#{name}_id".to_sym,
      :class_name => name.to_s.camelcase,
      :primary_key => :id
    }

    defaults.keys.each do |key|
      self.send("#{key}=", options[key] || defaults[key])
    end
  end

end
class HasManyOptions < AssocOptions
  # def initialize(name, self_class_name, options = {})
  #   if self_class_name.is_a?(String)
  #     fk = self_class_name.to_s.dup.downcase.concat("_id").to_sym
  #   elsif self_class_name.is_a?(Symbol)
  #     fk = self_class_name
  #   end
  #   
  #   op = options
  #   if options.empty?
  #     @class_name = name.to_s.camelcase.singularize
  #     @foreign_key = fk
  #     @primary_key = :id  
  #   else
  #     puts "HasManyOptions w/ options"
  # 
  #     @class_name = op[:class_name].nil? ? self_class_name.to_sym : op[:class_name]
  #     @foreign_key = op[:foreign_key].nil? ? fk : op[:foreign_key]
  #     @primary_key = op[:primary_key].nil? ? :id : op[:primary_key]
  #   end
  # end
  
  def initialize(name, self_class_name, options = {})
    defaults = {
      :foreign_key => "#{self_class_name.underscore}_id".to_sym,
      :class_name => name.to_s.singularize.camelcase,
      :primary_key => :id
    }

    defaults.keys.each do |key|
      self.send("#{key}=", options[key] || defaults[key])
    end
  end
end

module Associatable
  # Phase IVb
  def belongs_to(name, options = {})
    self.assoc_options[name] = BelongsToOptions.new(name, options)
    
    define_method(name) do
       options = self.class.assoc_options[name]
       key_val = self.send(options.foreign_key)
       options
         .model_class
         .where(options.primary_key => key_val)
         .first
     end

    
    
  end

  def has_many(name, options = {})
    self.assoc_options[name] = HasManyOptions.new(name, self.name, options)
    
    define_method(name) do
      options = self.class.assoc_options[name]

      key_val = self.send(options.primary_key)
      options
        .model_class
        .where(options.foreign_key => key_val)
    end
  end

  def assoc_options
    @assoc_options ||= {}
    @assoc_options
  end
end

class SQLObject
  # Mixin Associatable here...
  extend Associatable
end
