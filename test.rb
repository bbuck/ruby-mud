require 'config/config'

a = Config.new
a.test = "Hello"
puts a.test
puts a["test"]
