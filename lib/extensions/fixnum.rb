class Fixnum
  def long_time_string
    str = ""
    time = self
    years = time / 1.year.to_i
    time = time % 1.year.to_i

    months = time / 1.month.to_i
    time = time % 1.month.to_i

    weeks = time / 1.week.to_i
    time = time % 1.week.to_i

    days = time / 1.day.to_i
    time = time % 1.day.to_i

    hours = time / 1.hour.to_i
    time = time % 1.hour.to_i

    minutes = time / 1.minute.to_i
    seconds = time % 1.minute.to_i

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