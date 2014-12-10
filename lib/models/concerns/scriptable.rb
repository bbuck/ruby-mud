module Scriptable
  extend ActiveSupport::Concern

  included do
    attr_accessor :_engine
    class_attribute "_script_var_name"
    class_attribute "_engines"
    class_attribute "_default_script"

    after_save :reload_engine, if: :script_changed?
    before_save :set_default_script, if: :script_is_blank?
  end

  module ClassMethods
    def script_var_name(name)
      self._script_var_name = "@#{name}"
    end

    def engines
      self._engines ||= []
    end

    def reload_engine(id, script)
      if engine = _engines[id]
        engine.reset
        engine.evaluate(script)
      end
    end

    def default_script(str = nil)
      if str.present?
        self._default_script = str
      else
        self._default_script
      end
    end
  end

  def reload_engine
    reload
    script_engine.reset
    script_engine.evaluate(self.script || "")
  end

  def update_script_variables(engine)
    engine[self.class._script_var_name] = self
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
    update_script_variables(_engine)
    _engine
  end

  protected

  def script_is_blank?
    script.blank?
  end

  def set_default_script
    self.script = self.class.default_script
  end
end
