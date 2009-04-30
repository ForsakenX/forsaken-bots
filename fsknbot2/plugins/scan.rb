IrcCommandManager.register 'scan', 'looks for hosts' do |m|
  return if m.private
  case m.args.shift
  when 'block'
    m.reply ScanCommand.block(m)
  when 'unblock'
    m.reply ScanCommand.unblock(m)
  else

    return if ScanCommand.scanning
    ScanCommand.scanning = true
    ScanCommand.run do |results|
      hosts = []
      results[:hosts].each{|u| hosts << u.hostmask }
  
        time_taken = results[:time_finished] - results[:time_started]
  
      output  = "#{hosts.length} hosting"
      output += ": #{hosts.join(', ')}  " if hosts.length > 0
      #output += "Scanned #{users.length} users in #{time_taken} seconds."
  
      m.reply output
  
      ScanCommand.scanning = false
    end
  
  end
end

class ScanCommand
  class << self
    @@blocked = []
    @scanning = false
    attr_accessor :scanning
    def run
  
      EnetTest::find_hosts( users ) do |results|

        yield results if block_given?

        results[:hosts].each {|u| Game.create({:host => u}) }

      end

    end
    def users
      list = IrcUser.unique_by_ip
      @@blocked.each do |user|
        # remove blocked users 
        list.delete user
        # and any other user from their ip
        list.dup.each do |u|
          list.delete u if u.ip == user.ip
        end
      end
      list
    end
    def block m
      @@blocked << m.from
      @@blocked.uniq!
      "You have been temporarly blocked from scans."
    end
    def unblock m
      @@blocked.delete m.from
      "You have been unblocked."
    end
  end
end


