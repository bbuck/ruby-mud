class Fixnum
  def seconds
    self
  end

  def minutes
    seconds * 60
  end
  alias_method :minute, :minutes

  def hours
    minutes * 60
  end
  alias_method :hour, :hours

  def days
    hours * 24
  end
  alias_method :day, :days

  def weeks
    days * 7
  end
  alias_method :week, :weeks

  def months
    days * 30
  end
  alias_method :month, :months

  def years
    weeks * 52
  end
  alias_method :year, :years

  def long_time_string
    str = ""
    time = self
    years = time / 1.year
    time = time % 1.year

    months = time / 1.month
    time = time % 1.month

    weeks = time / 1.week
    time = time % 1.week

    days = time / 1.day
    time = time % 1.day

    hours = time / 1.hour
    time = time % 1.hour

    minutes = time / 1.minute
    seconds = time % 1.minute

    str += "#{years} years " if years > 0
    str += "#{months} months " if months > 0
    str += "#{weeks} weeks " if weeks > 0
    str += "#{days} days " if days > 0
    str += "#{hours} hours " if hours > 0
    str += "#{minutes} minutes " if minutes > 0
    str += "#{seconds} seconds" if seconds > 0
    str.strip
  end
end