class IrcCommandManager
  class << self

    @@help = {}; def help; @@help; end
    @@commands = {}; def commands; @@commands; end

    def call command, msg
      return unless @@commands[ command ]
      @@commands[ command ].call(msg)
    end

    # register both at once or one at a time
    def register command, help=nil, &block
      @@help[ command ] = help unless help.nil?
      @@commands[ command ] = block if block_given?
    end

  end
end
