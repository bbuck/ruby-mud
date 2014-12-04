class Enumerize::Attribute
  def numeric_values
    @value_hash.keys.map { |k| k.to_i }.reject { |k| k == 0 }
  end
end