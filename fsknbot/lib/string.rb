class String

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

end
