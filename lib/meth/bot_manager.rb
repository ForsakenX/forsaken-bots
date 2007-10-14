  class Meth::BotManager
    @@bots = {}
    class << self
      def bots; @@bots; end
      def connect(config)
        begin
          bot = Meth::Bot.new(config)
          @@bots[bot.name] = bot
          puts "Connecting #{bot.name} to #{bot.server}:#{bot.port}"
          EM::connect(bot.server, bot.port, bot)
        rescue
          puts "Error: #{$!}"
          $@.each do |line| puts "#{line}" end
        end
      end
    end
  end


