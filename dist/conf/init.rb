puts "init loaded"

# load lib
Dir["#{DIST}/lib/*.rb"].each do |m|
  if FileTest.executable?(m)
    require m
    puts "Loaded #{File.basename(m)}"
  end
end

# load up keyboard listener
if $config['keyboard']
  if Object.const_defined?($config['keyboard']['handler'])
    EM.open_keyboard(KeyboardHandler)
    puts "Opened keyboard for inputs"
  end
end

