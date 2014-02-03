module Util
  def require_file path, file = __FILE__
    require File.expand_path(path, file)
  end
end