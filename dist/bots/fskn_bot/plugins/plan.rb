class Plan < Meth::Plugin

  @@planned = [
    # {
    #   user => user,
    #   time => time,
    #   description => ""
    # }
  ]

  def initialize *args
    super *args
    @bot.command_manager.register("plan",self)
    @bot.command_manager.register("planned",self)
  end

  def help m
    case m.params.shift
    when "plan"
      ""
    when "planned"
      "planned => Display planned games..."
    end
  end

  def command m
    case m.command
    when "plan"
      plan m
    when "planned"
      planned m
    end
  end

  def planned m
  end

  def plan m
    (time, desc) = m.slice(m.command).message.split(',')
    @@planned[] << {
      user => m.user,
      time => Time.new(),
      desc => desc,
    }
  end

end

