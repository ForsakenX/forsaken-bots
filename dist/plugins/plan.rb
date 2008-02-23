class Plan < Meth::Plugin

  def initialize *args
    super *args
    @bot.command_manager.register("plan",self)
    @bot.command_manager.register("unplan",self)
    @bot.command_manager.register("planned",self)
    @db = "#{BOT}/db/plans.yaml"
    @plans = (FileTest.exists?(@db) && YAML.load_file(@db)) || []
    @timer = EM::PeriodicTimer.new(1.minutes){ check_plans }
  end

  def cleanup *args
    super *args
    @timer.cancel unless @timer.nil?
  end

  def help m=nil, topic=nil
    h = {
      :plan => "plan <time> [daily] => Add a plan to the list...",
      :unplan => "unplan <index> => Remove plan by index number...",
      :planned => "planned => Display planned games..."
    }
    [:plan,:unplan,:planned].map{|n|h[n]}.join(',  ')
  end

  def command m
    m.reply "fuck off, I'm not ready yet bitch..."
    return
    case m.command
    when "plan"
      plan m
    when "planned"
      planned m
    when 'unplan'
      unplan m
    end
  end

  def unplan m
    i = m.params.shift.to_i
    @plans.delete_at(i)
    save
    check_plans
    m.reply "Plan removed..."
  end

  def planned m
    if @plans.length < 1
      m.reply "There are no plans..."
      return
    end
    output = []
    @plans.each_with_index do |plan,x|
      output << "#{x}: #{plan[:user]} #{plan[:time]}"
    end
    m.reply output.join('; ')
  end

  def plan m
    if m.channel.nil? or m.channel.name.downcase != "#forsaken"
      m.reply "This command is only valid in #forsaken"
    end
    params = m.params.dup
    time = params.shift
    daily = params.shift
    if time.nil?
      m.reply "Missing time.  "+help(m,:plan)
      return
    else
      unless time =~ /(am|pm)/
        time = "#{time}am"
      end
      _time = time.dup
      am_pm = _time.slice!(/(am|pm)/)
      pm = ($1 == "pm")
      am = !pm
      (hour,minute) = _time.split(':')
      unless hour =~ /^[0-9]+$/
        m.reply "Bad value for hour: '#{hour}'"
        return
      end
      hour = hour.to_i
      hour += 12 if pm
      hour = 0 if (am && (hour == '12'))
      if hour < 0 || hour > 24
        m.reply "Bad value for hour: '#{hour}'"
        return
      end
      if minute.nil?
        minute = 0
      elsif ! (minute =~ /^[0-9]+$/)
        m.reply "Bad value for minute."
        return
      end
      minute = minute.to_i
      if minute < 0 or minute > 59
        m.reply "Bad value for minute."
        return
      end
      seconds = hour.hours
      seconds += minute.minutes
    end
    if daily.nil?
      daily = false
    else
      daily = (daily=="daily")||false
    end
    @plans << {
      :user => m.source.nick,
      :time => time,
      :seconds => seconds,
      :daily => daily
    }
    save
    check_plans
    m.reply "Plan created..."
  end

  private

  def find_earliest
    return nil if @plans.empty?
    earliest = nil
    @plans.each { |plan|
      next unless earliest.nil? || plan[:seconds] < earliest[:seconds]
      earliest = plan
    }
    earliest
  end

  def check_plans
    earliest = find_earliest
    return if earliest.nil?
    earliest
  end

  def save
    f = File.open(@db,'w+')
    YAML.dump(@plans,f)
    f.close
  end

end

