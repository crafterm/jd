class Time
  
  FORMATS = {
    :iso8601 => '%Y-%m-%dT%H:%MZ',
    :posted  => '%d %B %Y'
  }
  
  def to_s(requested)
    self.strftime(FORMATS[requested])
  end
  
end