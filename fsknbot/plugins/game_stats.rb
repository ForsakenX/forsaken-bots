require 'time'
class GameStats < Meth::Plugin

  def initialize *args
    super *args
    # storage
    @db = File.expand_path("${ROOT}/db/game_stats.yaml")
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
      next if @game_stats[:taken] < 10.minutes
      save
    }
    GameModel.event.register("game.finished",@game_stopped)
    # commands
    @bot.command_manager.register('stats',self)
    @games_listener = Proc.new{|m| games(m) }
    @bot.event.register('meth.command.!games',@games_listener)
  end

  def cleanup *args
    super *args
    GameModel.event.unregister("game.finished",@game_stopped)
    @bot.event.unregister('meth.command.!games',@games_listener)
  end

  def help m=nil, topic=nil
    h = {
      :played  => "played => Shows number of games played.",
      :hosted  => "hosted [full] => Shows how many times people hosted.  "+
                  "without [full] hides % < 2",
      :last    => "last => Show last game played.",
      :first   => "first => Show first game played.",
      :longest => "longest => Show the longest game.",
      :average => "average => Show average of games played."
    }
    (topic = m.nil? ? nil : m.params[0]) if topic.nil?
    if topic.nil?
      result = "stats has the following options: " + 
               h.keys.map{|k|k.to_s}.sort.join(', ')
    else
      result = h[topic.to_sym]
    end
    return result
  end

  def games m
    weekday = Time.now.strftime("%A")
    average = average_per_weekday(weekday)[weekday]
    hours   = 24
    count_hours = number_of_games_since(Time.now-hours.hours)
    count_today = number_of_games_since(Time.parse("12am"))
    m.reply "Average #{average} games on #{weekday}, "+
            "#{count_today} played today, "+
            "#{count_hours} in last #{hours} hours."
  end

  def command m
    @m = m
    @params = m.params.dup
    case @params.shift
    when "played"
      m.reply played
    when "hosted"
      m.reply hosted
    when "first"
      m.reply first
    when "last"
      m.reply last
    when "longest"
      m.reply longest
    when "average"
      m.reply average
    when "",nil
      m.reply help
    end
  end

  def last
    game = @game_stats.last
    user = game[:user]
    start = game[:start].strftime("%m/%d/%Y %I:%M%p")
    duration = duration_to_human(game[:taken])
    "Last game was hosted by #{user} at #{start} for #{duration}."
  end

  def hosted
    total = @game_stats.length
    users = Hash.new(0)
    @game_stats.each{|game|users[game[:user].downcase] += 1}
    users = users.sort.map{|entry|
      percent = (entry[1]/total.to_f*100).to_i
      next if @m.params[1] != "full" && percent < 2
      "#{entry[0]} (#{entry[1]}, #{percent}%)"
    }
    "Games hosted by user: #{users.compact.join(', ')}"
  end

  def played
    games = @game_stats.length
    "There has been #{games} games played "+since
  end

  def first
    game = @game_stats[0]
    user = game[:user]
    start = game[:start].strftime("%m/%d/%Y %I:%M%p")
    duration = duration_to_human(game[:taken])
    "First game was hosted by #{user} on #{start} for #{duration}.  "+
    "This date is used for calculations."
  end

  def longest
    longest = @game_stats[0]
    @game_stats.each {|stats|
      longest = stats if stats[:taken] > longest[:taken]
    }
    date = longest[:start].strftime("%m/%d/%Y")
    duration = duration_to_human(longest[:taken])
    host = longest[:user]
    "Longest game was "+
    "#{duration} long "+
    "hosted by #{host} "+
    "on #{date}"
  end

  def average
    per_weekday = []
    average_per_weekday.each do |weekday,average|
      per_weekday << "#{average} on #{weekday}"
    end
    "Game Averages: "+
    "{ #{average_per_day} per day } "+
    "{ #{per_weekday.join(', ')} }"
  end

  private

  def number_of_games_since time
    count = 0
    @game_stats.reverse.each do |stats|
      break if stats[:start] < time
      count += 1
    end
    count
  end

  def average_per_day
    ((@game_stats.length.to_f/number_of_days.to_f)*10.0).round/10.0
  end

  def average_per_weekday weekday="all"
    weekdays = count_games_per_weekday(weekday)
    weekdays.keys.each do |_weekday|
      next if weekday != "all" &&_weekday != weekday
      i = weekdays[_weekday].to_f / number_of_weeks.to_f
      i = (i.to_f*10.0).round/10.0
      weekdays[_weekday] = i
    end
    weekdays
  end

  def count_games_per_weekday weekday="all"
    weekdays = {"Sunday"=>0,"Monday"=>0,"Tuesday"=>0,"Wednesday"=>0,
                "Thursday"=>0,"Friday"=>0,"Saturday"=>0}
    @game_stats.each do |stats|
      _weekday = stats[:start].strftime("%A")
      next if weekday != "all" && _weekday != weekday
      weekdays[_weekday] += 1
    end
    weekdays
  end

  def number_of_weeks
    number_of_days / 7
  end

  def number_of_days
    (Time.now - @game_stats[0][:start]) / (60*60*24)
  end

  def since
    earliest = @game_stats[0][:start].strftime("%m/%d/%Y")
    "since #{earliest}"
  end

  def duration_to_human str
    plural = Proc.new{|i|i>1?"s":""}
    n = str.to_i
    minutes = n / 60
    seconds = n % 60
    hours = minutes / 60
    minutes = minutes % 60
    output = ""
    output += "#{hours} hour#{plural.call(hours)} " if hours > 0
    output += " and " if !(seconds > 0) && minute > 0
    output += " #{minutes} minute#{plural.call(minutes)} " if minutes > 0
    output += " and " unless seconds < 1
    output += "#{seconds} second#{plural.call(seconds)} " if seconds > 0
    output = output.gsub(/ +/,' ').clean_ends
    output
  end

  def save
    file = File.open(@db,'w+')
    YAML.dump(@game_stats,file)
    file.close
  end

end
