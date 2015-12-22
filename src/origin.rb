require_relative 'with_conditions'

module OriginSource
  def get_origin
    self
  end
end

module Origin
  include WithConditions
  include OriginSource

  def origin_method_names
    instance_methods(true).concat(private_instance_methods(true))
  end

  def origin_methods
    origin_method_names.map { |name| origin_method name }
  end

  def origin_method name
    instance_method name
  end

  def transform methods, &block
    methods.each{ |method| method.instance_eval &block }
  end

  def call_unbound unbound_method, *args
    unbound_method.bind(self).call *args
  end
end

class Module
  include Origin
end

class Object
  include Origin

  def instance_methods all
    methods all
  end

  def private_instance_methods all
    private_methods all
  end

  def instance_method sym
    owner = singleton_class
    origin_method = method(sym).unbind
    origin_method.send :define_singleton_method, :owner, proc{ owner }

    return origin_method
  end
end

class Regexp
  include OriginSource

  def get_origin
    valid_constants = Object.constants.select{ |c| self.match(c) and Object.const_get(c).is_a? Module }
    valid_constants.map{ |c| Object.const_get(c) }
  end
end

class Array
  include OriginSource

  def get_origin
    throw ArgumentError('origen vacio') if invalid?
    # si llegue aca es porque lo que tiene el array son si o si clases o modulos, no hay expresiones regulares en el array
    # el includes_all siempre va a devolver una clase, porque son las unicas que van a incluir a los modulos
    /.*/.get_origin.select{|c| includes_all? c }
  end


  # para lo que haya en el array, si es una clase, "something" debe ser ella, y si es un modulo, entonces la clase tiene que incluirlo
  # en cambio, si ese something es un modulo, nunca va a pasar que el modulo incluya a la clase, si es que hay una.
  # si estoy seleccionando todas las clases que cumplen con eso
  def includes_all? something
    all?{|module_or_class| something.is_a? module_or_class or something.ancestors.include? module_or_class}
  end

  def invalid?
    empty? or select{|m| m.is_a? Module or m.is_a? Class}.size == 1 or select{|c| c.is_a? Class}.size > 1 or any?{|m| !m.is_a? Class and
    !m.is_a? Module}
  end
end