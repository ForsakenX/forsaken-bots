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
        :user  => game.user.nick.downcase,
        :start => game.start_time,
        :end   => time,
        :taken => time - game.start_time
      }
      save
    }
    GameModel.event.register("game.finished",@game_stopped)
    # commands
    @bot.command_manager.register('stats',self)
  end

  def cleanup *args
    super *args
    GameModel.event.unregister("game.finished",@game_stopped)
  end

  def help m=nil, topic=nil
    h = {
      :played => "played => Shows number of games played.",
      :hosted => "hosted => Shows how many times people hosted.",
      :taken  => "last => Show last game played."
    }
    (topic = m.nil? ? nil : m.params[0]) if topic.nil?
    if topic.nil?
      result = h.keys.map{|t|h[t]}.join('  ')
    else
      result = h[target.to_sym]
    end
    return result
  end

  def command m
    @params = m.params.dup
    case @params.shift
    when "played"
      m.reply played
    when "hosted"
      m.reply hosted
    when "last"
      m.reply last
    when "",nil
      m.reply help
    end
  end

  private

  def last
    game = @game_stats.last
    user = game[:user]
    start = game[:start].strftime("%m/%d/%Y %I:%M%p")
    duration = duration_to_human(game[:taken])
    "Last game was hosted by #{user} at #{start} for #{duration}."
  end

  def hosted
    users = Hash.new(0)
    @game_stats.each{|game|users[game[:user].downcase] += 1}
    users = users.sort.map{|entry|"#{entry[0]} (#{entry[1]})"}
    "Games hosted by user: #{users.join(', ')}"
  end

  def played
    games = @game_stats.length
    "There has been #{games} games played "+since
  end

  def since
    earliest = @game_stats[0][:start].strftime("%m/%d/%Y")
    "since #{earliest}"
  end

  def duration_to_human str
    n = str.to_i
    minutes = n / 60
    seconds = n % 60
    hours = minutes / 60
    minutes = minutes % 60
    output = ""
    output += "#{hours} hours " if hours > 0
    output += " and " if !(seconds > 0) && minute > 0
    output += " #{minutes} minutes " if minutes > 0
    output += " and " unless seconds < 1
    output += "#{seconds} seconds " if seconds > 0
    output = output.gsub(/ +/,' ').clean_ends
    output
  end

  def save
    file = File.open(@db,'w+')
    YAML.dump(@game_stats,file)
    file.close
  end

end
