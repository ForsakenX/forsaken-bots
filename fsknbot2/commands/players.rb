
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
        add m.args.map{|p|p.downcase}
        "Player(s) have been added :]"
      else
        "Unknown Option: "+HelpCommand.run('player')
      end
    end

    def players m
      return "There are no players :[" if list.empty?
      list.sort.join(', ')
    end

    def add players
      l = list
      l << players
      save l.flatten
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

