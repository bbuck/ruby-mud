module Scriptable
  extend ActiveSupport::Concern

  included do
    attr_accessor :_engine
    class_attribute "_script_var_name"
    class_attribute "_engines"
  end

  module ClassMethods
    def script_var_name(name)
      self._script_var_name = "@#{name}"
    end

    def engines
      self._engines ||= []
    end
  end

  def reload_engine
    script_engine.reset
    script_engine.evaluate(self.script || "")
  end

  def script_engine
    reload
    self._engine ||= begin
      self.class.engines[id] ||= begin
        engine = ES::SharedEngine.new
        engine.evaluate(self.script || "")
        engine
      end
    end
    _engine[self.class._script_var_name] = self
    _engine
  end
end