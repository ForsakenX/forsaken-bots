class String

=begin
Case Helpers
=end

  # "FooBar".snake_case #=> "foo_bar"
  def snake_case
    gsub(/\B[A-Z]/, '_\&').downcase
  end

  # "foo_bar".camel_case #=> "FooBar"
  def camel_case
    split('_').map{|e| e.capitalize }.join
  end

  def snake_case!
    replace snake_case
  end

  def camel_case!
    replace camel_case
  end

=begin
Regex Helpers
=end

  def parse_regex
    self =~ (/^\/(.+)\/$/m)
    $1.nil? ? false : $1
  end

  def test_regex
    begin
      if (regex = parse_regex)===false
        raise "String `#{self}' does not look like Regex"
      end
      Regexp.new(regex)
      return true
    rescue Exception => e
      return e
    end
  end

=begin
Cleaners
=end

  def clean_ends
    self.gsub(/^ +/,'').gsub(/ +$/,'')
  end

end
