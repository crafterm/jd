class Time
  
  FORMATS = {
    :iso8601 => '%Y-%m-%dT%H:%MZ',
    :posted  => '%d %B %Y'
  }
  
  def to_s(requested)
    self.strftime(FORMATS[requested])
  end
  
end

class Array
  
  def total_pages
    (self.size.to_f / page_size.to_f).ceil
  end
  
  def page(page_number = 0)
    page_number = 1 if page_number < 1
    base = (page_number - 1) * page_size
    self[base..(base + page_size - 1)]
  end
  
  def page_size
    3
  end

end