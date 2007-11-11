class Alias < Meth::Plugin
  attr_reader :aliases
  def initialize *args
    super *args
    @bot.command_manager.register("alias",self)
    @bot.command_manager.register("aliasrm",self)
    @bot.command_manager.register("aliases",self)
    @db = "#{DIST}/bots/#{$bot}/db/aliases.yaml"
    if File.exists?(@db) 
      unless @aliases = YAML.load_file(@db)
        @bot.logger.warn "[ALIAS] could not load #{@db}..."
        @aliases = {}
      end
      @aliases.each do |new,old|
        do_alias(new,old)
      end
    else
      @bot.logger.warn "[ALIAS] #{@db} does not exist..."
      @aliases = {}
    end
  end
  def help m
    case m.params[0]
    when "alias"
      "alias [new] [old] => Sets an alias for [old] called [new]."
    when "aliasrm"
      "aliasrm [new] => Removes [old] alias."
    when "aliases"
      "aliases => Display aliases."
    else
      "alias#help called with unregistered command '#{m.params[0]}'."
    end
  end
  def command m
    case m.command
    when "alias"
      cmd_alias m
    when "aliasrm"
      cmd_aliasrm m
    when "aliases"
      cmd_aliases m
    end
  end
  def cmd_aliases m
    if @aliases.length < 1
      m.reply "There are no aliases set."
      return
    end
    aliases = []
    @aliases.each do |old,new|
      aliases << "#{new} => #{old}"
    end
    m.reply aliases.join(', ')
  end
  def cmd_aliasrm m
    name = m.params.shift
    unless @aliases[name]
      m.reply "#{name} is not an alias."
      return
    end
    @aliases.delete(name)
    @bot.command_manager.commands.delete(name)
    m.reply "Alias has been removed..."
    save
  end
  def cmd_alias m
    (new,old) = m.params
    unless old_command = @bot.command_manager.commands[old]
      m.reply "Note #{old} does not exist..."
    end
    if @bot.command_manager.commands[new]
      m.reply "Command #{new} allready exists..."
      return
    end
    do_alias(new,old)
    m.reply "Alias created..."
  end
  def do_alias(new,old)
    if @bot.command_manager.commands[new]
      @bot.logger.info "[ALIAS] command '#{new}' allready exists."
      return 
    end
    unless o = @bot.command_manager.commands[old]
      @bot.logger.error "[ALIAS] old command '#{old}' did not exist"
      return
    end
    @bot.command_manager.register(new,o[:obj],o[:callback])
    @aliases[new] = old
    @bot.logger.warn "[ALIAS] aliased #{new} to #{old}"
    save
  end
  private
  def save
    YAML.dump(@aliases,File.open(@db,'w+'))
  end
end
