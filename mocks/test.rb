
require 'observe'

events = { :a => Observe.new }

events[:a].register do |*args|
  puts args.inspect
end

events[:a].notify( 1 )

