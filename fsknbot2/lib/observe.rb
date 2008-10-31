class Observe
  def initialize
    @observers = []
  end
  def register &block
    @observers << block
  end
  def call *args
    @observers.each{|o|o.call(*args)}
  rescue Exception
    puts_error __FILE__,__LINE__
  end
end
