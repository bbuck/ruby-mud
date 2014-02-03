class Configuration < Hash
  def method_missing(name, *args)
    if name.to_s.end_with?('=') && args.length > 0
      self[name[0..-2].to_sym] = args[0]
    else
      self[name] ||= Configuration.new
    end
  end
end