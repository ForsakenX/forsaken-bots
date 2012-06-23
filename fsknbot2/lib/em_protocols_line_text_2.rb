module EM::Protocols::LineText2

  ## helper to send data with new line appended
  def send_line line
    t=Time.now.strftime("%m-%d-%y %H:%M:%S")
    puts "irc #{t} <<< #{line}"
    send_data "#{line}\n" unless line.nil?
  end

end
