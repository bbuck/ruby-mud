ES::SharedEngine.new.evaluate <<-ES
# Null out prints

class ::IO
  @@print do
    Errors < "A script attempted to perform a log"
  end

  @@println do
    Errors < "A script attempted to perform a log"
  end

  print do
    Errors < "A script attempted to perform a log"
  end

  println do
    Errors < "A script attempted to perform a log"
  end
end

# Polyfill random into list until added to ES Core
# Allows [1, 2, 3].random to return a random item in
# the list

class ::List
  random do
    key_list = keys
    index = Random.int(0, key_list.length)
    key_list[key]
  end
end

# Helpers for sending text
$no_prompt = [:prompt => no]
$no_newline = [:newline => no]
$no_prompt_or_newline = [:prompt => no, :newline => no]
ES
