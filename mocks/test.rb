
class Foo
  class << self

    def bar
      false ||
      1
    end

  end
end

puts Foo.bar
