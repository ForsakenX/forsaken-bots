
IrcCommandManager.register 'players', 'List all players' do |m|
  m.reply Player.players(m)
end

IrcCommandManager.register 'player', 'player add <player>: Add a player' do |m|
  m.reply Player.player(m)
end

require 'yaml'
class Player
  class << self

    @@db = File.expand_path("#{ROOT}/db/players.yaml")

    def player m
      case m.args.shift
      when 'add'
        add m.args
        "Player(s) have been added :]"
      else
        "Unknown Option: "+HelpCommand.run('player')
      end
    end

    def players m
      l = list
      "#{list.length} players: #{list.join(', ')}"
    end

    def add players
      l = list
      [players].flatten.each do |p|
        next if l.detect{|_l| _l.downcase == p.downcase }
        l << p
      end
      save l.flatten.sort
    end

    def list
      File.exists?(@@db) ? (YAML.load_file(@@db)||[]) : []
    end

    def save l
      file = File.open(@@db,'w+')
      YAML.dump(l,file)
      file.close
    end

  end
end

