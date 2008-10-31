
def x &block
  block.call 1
end

def y &block
  x &block
end

y do |arg|
  puts arg
end

