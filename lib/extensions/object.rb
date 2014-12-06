class Object
  def extend_methods_from(mod)
    method_names = mod.methods - Module.methods
    method_names.each do |name|
      singleton_class.send(:define_method, name, &mod.method(name))
    end
  end
end
