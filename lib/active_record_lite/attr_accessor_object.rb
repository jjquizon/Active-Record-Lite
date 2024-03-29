class AttrAccessorObject
  def self.my_attr_accessor(*names)
    names.each do |name|
      define_method "#{name}" do
        instance_variable_get "@#{name}"
      end
    end
    
    names.each do |name|
      define_method "#{name}=" do |argument|
        instance_variable_set "@#{name}", argument
      end
    end 
  end
end
