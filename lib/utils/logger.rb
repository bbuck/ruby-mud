# Log Level:
# 4 - Verbose
# 3 - Debug
# 2 - Info
# 1 - Error
class Logger
  VERBOSE = 4
  DEBUG = 3
  INFO = 2
  ERROR = 1

  attr_accessor :log_level

  def initialize(log_level = 5)
    @log_level = log_level
  end

  def log(type, text)
    send(type, text)
  end

  def verbose(text)
    if log_level >= VERBOSE
      puts "[f:green]VERBOSE:[reset] #{text}".colorize
    end
  end

  def debug(text)
    if log_level >= DEBUG
      puts "[f:blue]DEBUG:[reset] #{text}".colorize
    end
  end

  def info(text)
    if log_level >= INFO
      puts "[f:green:b]INFO:[reset] #{text}".colorize
    end
  end

  def error(text)
    if log_level >= ERROR
      puts "[f:red:b]ERROR:[reset] #{text}".colorize
    end
  end
end