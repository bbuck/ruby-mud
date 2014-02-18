module HashExtensions
  def merge(o_hash)
    if o_hash.kind_of?(ES::EleetToRubyWrapper)
      self.each do |key, value|
        if o_hash[key].nil?
          o_hash[key] = value
        end
      end
      o_hash
    else
      super
    end
  end
end

class Hash
  prepend HashExtensions
end