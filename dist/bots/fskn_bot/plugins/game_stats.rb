class GameStats < Meth::Plugin

  def initialize *args
    super *args
    # storage
    @db = File.expand_path("#{BOT}/db/game_stats.yaml")
    @game_stats = File.exists?(@db) ? (YAML.load_file(@db)||[]) : []
    # events
    @game_stopped = Proc.new{|game|
      time = Time.now
      @game_stats << {
        :user  => game.user,
        :start => game.start_time,
        :end   => time,
        :taken => time - game.start_time
      }
    }
    GameModel.event.register("game.finished",@game_stopped)
  end

  def cleanup
    GameModel.event.unregister("game.finished",@game_stopped)
  end

  private

  def save
    file = File.open(@db,'w+')
    YAML.dump(@game_stats,file)
    file.close
  end

end
