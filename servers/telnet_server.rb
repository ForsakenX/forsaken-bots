class TelnetServer < EM::Connection

  include EM::Protocols::LineText2

  @@prompt = "\n#> "

  def post_init
    super
    @tarpit = Object.new;
    port, ip = Socket.unpack_sockaddr_in(get_peername)
    puts "New Telnet Connection from #{ip}:#{port} @ #{Time.now}"
    send_data
  end

  def unbind
    puts "Closing a Telnet Connection @ #{Time.now}"
  end

  def receive_line line
    begin
      # compile errors seem to still crash the server!
      send_data "=> " + @tarpit.instance_eval(line).inspect
    rescue RuntimeError
      send_data $!
    rescue
      send_data $!
    end
    puts "Received Data on Telnet Connection @ #{Time.now}"
  end

  private

  def send_data(data="")
    return false unless data.respond_to?(:to_s)
    super data.to_s + @@prompt
  end

end
