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
    @bot.command_manager.register("unplan",self)
    @bot.command_manager.register("planned",self)
  end

  def help m=nil, topic=nil
    case (topic||m.params.shift)
    when "plan"
      "plan [description] => Add a plan to the list..."
    when "unplan"
      "unplan [index] => Remove plan by index...  To get index type planned."
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
    when 'unplan'
      unplan m
    end
  end

  def unplan m
    i = m.params.shift.to_i
    @@planned.delete_at(i)
    m.reply "Plan removed..."
  end

  def planned m
    if @@planned.length < 1
      m.reply "There are no plans..."
      return
    end
    output = []
    @@planned.each_with_index do |plan,x|
      output << "#{x}: #{plan[:user]} says #{plan[:desc]}"
    end
    m.reply output.join('; ')
  end

  def plan m
    message = m.message
    message.slice!(m.command)
    if message == ""
      m.reply "Missing description.  Type help plan for more info."
      return
    end
    @@planned << {
      :user => m.source.nick,
      :desc => message,
    }
    m.reply "Plan created..."
  end

end

