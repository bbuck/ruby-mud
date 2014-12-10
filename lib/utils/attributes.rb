module Game
  class Attributes
    class << self
      def define_attributes(&block)
        self.class_eval(&block)
      end

      def load(yaml)
        Attributes.new(yaml)
      end

      def dump(obj)

      end

      def attributes
        @attributes.dup
      end

      private

      def define_attribute(name)
        name = name.downcase.to_sym
        (@attributes ||= []) << name
        self.class_eval do
          attr_accessor name
        end
      end
    end

    def initialize(yaml)
      hash = YAML.load(yaml)
      hash.each do |attribute, value|
        method = "#{attribute}="
        if respond_to?(method)
          send(method, value)
        end
      end
    end

    def to_yaml
      hash = self.class.attributes.inject({}) do |hash, attr|
        if respond_to?(attr)
          hash[attr] = send(attr)
        end
        hash
      end
      hash.to_yaml
    end
  end
end