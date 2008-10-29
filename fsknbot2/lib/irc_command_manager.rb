class IrcCommandManager
  class << self

    @@help = {}; def help; @@help; end
    @@commands = {}; def commands; @@commands; end

    def call command, msg
      return unless @@commands[ command ]
      @@commands[ command ].call(msg.dup)
    end

    # register both at once or one at a time
    def register commands, help=nil, &block
      [commands].flatten.each do |command|
        @@help[ command ] = help unless help.nil?
        @@commands[ command ] = block if block_given?
      end
    end

  end
end
