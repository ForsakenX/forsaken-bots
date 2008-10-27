class IrcCommandManager

  # execute command
  def self.call command, msg
    @msg = msg
    self.send command if respond_to? command
  end

end
