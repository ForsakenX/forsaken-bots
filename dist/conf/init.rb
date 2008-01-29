puts "Running init.rb"

# load lib
puts "Loading Global lib/models"
Dir["#{DIST}/lib/*.rb","#{DIST}/models/*.rb","#{DIST}/lib/*.so"].each do |m|
  if FileTest.executable?(m)
    require m
    puts "Loaded #{File.basename(m)}"
  end
end

# load up keyboard listener
puts "Loading Keyboard Handler"
if $config['keyboard']
  if Object.const_defined?($config['keyboard'])
    EM.open_keyboard(KeyboardHandler)
    puts "Opened keyboard for inputs"
  end
end

puts "Loading Bot lib"
Dir["#{DIST}/bots/#{$bot}/lib/*.rb"].each do |m|
  if FileTest.executable?(m)
    require m
    puts "Loaded: #{File.basename(m)}"
  end
end

puts "Loading Bot models"
Dir["#{DIST}/bots/#{$bot}/models/*.rb"].each do |m|
  if FileTest.executable?(m)
    require m
    puts "Loaded: #{File.basename(m)}"
  end
end

