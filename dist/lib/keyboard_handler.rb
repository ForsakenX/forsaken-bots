class KeyboardHandler < EM::Connection
  include EM::Protocols::LineText2
  def receive_line keystrokes
    puts "I received the following data from the keyboard: #{keystrokes}"
  end
end
