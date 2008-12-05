IrcCommandManager.register 'scan', 'looks for hosts' do |m|
  return if m.private || ScanCommand.scanning
  ScanCommand.scanning = true
  ScanCommand.run do |results|
    hosts = []
    results[:hosts].each{|u| hosts << u.hostmask }

      time_taken = results[:time_finished] - results[:time_started]

    output  = "#{hosts.length} hosting"
    output += ": #{hosts.join(', ')}  " if hosts.length > 0
    #output += "Scanned #{users.length} users in #{time_taken} seconds."

    IrcConnection.chatmsg output

    ScanCommand.scanning = false
  end
end

class ScanCommand
  class << self
    @scanning = false
    attr_accessor :scanning
    def run
  
      DirectPlay::find_hosts( IrcUser.unique_by_ip ) do |results|

        yield results if block_given?

        results[:hosts].each {|u| Game.create({:host => u}) }

      end

    end
  end
end


