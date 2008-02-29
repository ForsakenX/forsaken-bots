class Numeric

=begin
Time Helpers
=end

  def seconds
    self
  end

  def minutes
    self * 60
  end

  def hours
    minutes * 60
  end

  def days
    hours * 24
  end

  def weeks
    days * 7
  end

end
