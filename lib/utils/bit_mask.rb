class BitMask
  class << self
    def load(value)
      new(value)
    end

    def dump(obj)
      unless obj.is_a?(self)
        raise ::ActiveRecord::SerializationTypeMismatch, "Attribute was supposed to be a #{self} but was #{obj.class} instead. -- #{obj.inspect}"
      end

      obj.value
    end
  end

  attr_reader :value

  def initialize(value = 0)
    @value = value
  end

  def <<(mask)
    add(mask)
  end

  def add(*masks)
    masks.each do |mask|
      @value |= mask_value(mask)
    end
    self
  end

  def remove(mask)
    @value &= ~mask_value(mask)
    self
  end
  alias_method :>>, :remove

  def has?(mask)
    mask = mask_value(mask)
    value & mask == mask
  end
  alias_method :=~, :has?

  def reset
    @value = 0
    self
  end

  def |(mask)
    value | mask_value(mask)
  end

  def &(mask)
    value & mask_value(mask)
  end

  def ^(mask)
    value ^ mask_value(mask)
  end

  def ~
    ~value
  end

  def to_s
    value.to_s(2)
  end

  def inspect
    "#<BitMask @value=#{value}>"
  end

  private

  def mask_value(obj)
    if obj.kind_of?(BitMask)
      obj.value
    elsif !obj.kind_of?(Fixnum)
      obj.to_i
    else
      obj
    end
  end
end