module ModelConcern
  def self.included(&block)
    @included = block
  end

  def self.included(base)
    base.extend(ClassMethods)
    if !@included.nil?
      @included.call(base)
    end
  end
end