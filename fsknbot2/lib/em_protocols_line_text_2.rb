module EM::Protocols::LineText2

  ## helper to send data with new line appended
  def send_line line
    puts "irc <<< #{line}"
    send_data "#{line}\n" unless line.nil?
  end

end
