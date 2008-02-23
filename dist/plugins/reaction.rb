class Reaction < Meth::Plugin

  def initialize *args
    super *args
    @bot.command_manager.register("react",self)
    @bot.command_manager.register("reaction",self)
    @db = File.expand_path("#{BOT}/db/reactions.yaml")
    @reactions = File.exists?(@db) ? YAML.load_file(@db) : []
  end

  def help(m=nil, topic=nil)
    short_help = "react has the following commands { to },  "+
                 "reaction has the following commands "+
                 "{ ls|list, rm|remove, ms|message, ch|chance, tg|target }  "+
                 "For detailed help on each command type:  "+
                 "`help reaction <command>'  "+
                 "EXAMPLES:  "+
                 "`help reaction to`  "+
                 "`help reaction list`"
    h = {
      :to       =>  "react to <target> with <message> [at <chance>% chance] => "+
                    "Display <message> when <target> is detected at <chance>.",
      :list     =>  "reaction ls|list [target] => "+
                    "List all targets or list replys for [target].",
      :remove   =>  "reaction rm|remove <target> (all|<index>|<start>-<stop>) => "+
                    "Remove all replies in range from reply list of <target>.",
      :message  =>  "reaction ms|message <target> <index> <message> =>  "+
                    "Changes <message> for <index>.",
      :chance   =>  "reaction ch|chance <target> <index> <chance>[%] =>  "+
                    "Changes <chance> for <index>.",
      :target   =>  "reaction tg|target <target> <index> <target> =>  "+
                    "Changes <target> for <index>.",
      :notes    =>  "NOTES: "+
                    "<target> can be regex pattern enclosed in //.  "+
                    "<target> is case insensitive.  "+
                    "<index> can be retreived from `reaction list'.",
      :example  =>  "EXAMPLE: "+
                    "react to game with Lets rock and roll! at 10% chance"
    }
    h_aliases = {
      :ls => :list,
      :rm => :remove,
      :ms => :message,
      :ch => :chance,
      :tg => :target,
    }
    topic = topic.to_sym unless topic.nil?
    if topic.nil?
      #topics_order = [:to,:list,:remove,:message,:change,:target,:notes,:example].map
      #return topics_order.map{|topic|h[topic]}.join('  ')
      return short_help
    end
    unless t = h[topic]
      unless t = h[h_aliases[topic]]
        message = "Unknown topic requested: #{topic}"
        if m.nil?
          throw message
        else
          return message
        end
      end
    end
    t
  end

  def command m
    case m.command
    when "react"
      react m
    when "reaction"
      reaction m
    end
  end

  def reaction m
    case m.params.shift
    when "ls","list"
      list m
    when "rm","remove"
      remove m
    when "ms","message"
      edit_message m
    when "ch","chance"
      edit_chance m
    when "tg","target"
      edit_target m
    end
  end

  def list m
    if @reactions.empty?
      m.reply "You have no reactions set."
      return
    end
    # list all targets
    unless target = m.params.shift
      m.reply targets.join(', ')
      return
    end
    # list replys for target
    if (reactions = find_all(target)).empty?
      m.reply "No reactions for `#{target}'"
      return
    end
    replys = []
    reactions.each_with_index{ |reaction,index|
      replys << "#{index.to_s}: #{reaction[:target]} => #{reaction[:message]} at #{reaction[:chance]}% chance"
    }
    m.reply replys.join(', ')
  end

  def remove m
    unless target = m.params.shift
      m.reply "Error: Missing <target>.  "+help(m,:remove)
      return
    end
    if (reactions = find_all(target)).empty?
      m.reply "No reactions for `#{target}'"
      return
    end
    index = m.params.shift
    if index == "all"
      start,stop = 0,(reactions.length-1)
    else
      unless index =~ /([0-9]+)(-([0-9]+)*){0,1}/
        m.reply "Error: Improper format for <index>.  "+help(m,:remove)
        return false
      end
      start,stop = $1.to_i,$3.to_i
    end
    # remove it
    removed = []
    if stop.nil?
      reaction = reactions[index]
      delete(reaction)
      removed << index
    else
      if start > stop
        m.reply "Error: #{start} is not lower than #{stop}."
        return false
      end
      reactions[start..stop].each_with_index do |reaction,index|
        delete(reaction)
        removed << index
      end
    end
    save
    m.reply "Done."
  end

  def edit_chance m
    unless target = m.params.shift
      m.reply "Error: Missing <target>.  "+help(m,:chance)
      return
    end
    if (reactions = find_all(target)).empty?
      m.reply "No reactions for `#{target}'"
      return
    end
    unless index = m.params.shift
      m.reply "Error: Missing <index>.  "+help(m,:chance)
      return
    end
    unless index =~ /^[0-9]*$/
      m.reply "Error: <index> must be a number."
      return false
    end
    index = index.to_i
    unless chance = m.params.shift
      m.reply "Error: Missing <chance>. "+help(m,:chance)
      return false
    end
    unless chance.nil?
      chance.slice!(/%$/)
      unless chance =~ /^[0-9]+$/
        m.reply "Errpr: Bad format for <chance>. "+help(m,:chance)
        return false
      end
    end
    unless reaction = reactions[index]
      m.reply "Reaction at index (#{index}) does not exist."
      return false
    end
    reaction[:chance] = chance
    save
    m.reply "Set chance to #{chance}%"
  end

  def edit_message m
    unless target = m.params.shift
      m.reply "Error: Missing <target>.  "+help(m,:message)
      return
    end
    if (reactions = find_all(target)).empty?
      m.reply "No reactions for `#{target}'"
      return
    end
    unless index = m.params.shift
      m.reply "Error: Missing <index>.  "+help(m,:message)
      return
    end
    unless index =~ /^[0-9]*$/
      m.reply "Error: <index> must be a number."
      return false
    end
    index = index.to_i
    if (message = m.params.join(' ')).empty?
      m.reply "Error: Missing <message>. "+help(m,:message)
      return false
    end
    unless reaction = reactions[index]
      m.reply "Reaction at index (#{index}) does not exist."
      return false
    end
    reaction[:message] = message
    save
    m.reply "Done."
  end

  def edit_target m
    unless target = m.params.shift
      m.reply "Error: Missing <target>.  "+help(m,:target)
      return
    end
    if (reactions = find_all(target)).empty?
      m.reply "No reactions for `#{target}'"
      return
    end
    unless index = m.params.shift
      m.reply "Error: Missing <index>.  "+help(m,:target)
      return
    end
    unless index =~ /^[0-9]*$/
      m.reply "Error: <index> must be a number."
      return false
    end
    index = index.to_i
    unless target = m.params.shift
      m.reply "Error: Missing <target>. "+help(m,:target)
      return false
    end
    unless reaction = reactions[index]
      m.reply "No reaction found."
      return false
    end
    reaction[:target] = target
    save
    m.reply "Done."
  end

  def react m
    # extract values
    unless m.params.shift == "to"
      m.reply "Missing keyword `to': "+help(m,:to)
      return
    end
    unless target = m.params.shift
      m.reply "Missing <word>: "+help(m,:to)
      return
    end
    unless m.params.shift == "with"
      m.reply "Missing keyword `from': "+help(m,:to)
      return
    end
    message = m.params.join(' ')
    message.slice!(/ at ([0-9]+)% chance/)
    chance = ($1.nil?) ? 100 : $1.to_i
    # prepare regex
    if regex = target.parse_regex
      unless (error = regex.test_regex)===true
        m.reply "Error: Regex not formated properly: #{error}"
        return false
      end
    end
    # create reaction
    reaction = {
      :target  => target,
      :message => message,
      :chance => chance
    }
    @reactions << reaction
    save
    m.reply "Done."
  end

  def privmsg m
    return if @bot.command_manager.commands[m.command]
    random = rand(100)
    @reactions.each do |reaction|
      next unless chance_play(reaction[:chance],random)
      if regex = reaction[:target].parse_regex
        search = regex
      else
        search = Regexp::escape(reaction[:target])
      end
      if m.message =~ /#{search}/i
        m.reply reaction[:message] 
      end
    end
  end

  private

  def save
    file = File.open(@db,'w+')
    YAML.dump(@reactions,file)
    file.close
  end

  def find target
    @reactions.find {|reaction| reaction[:target] == target }
  end

  def find_all target
    @reactions.find_all {|reaction| reaction[:target] == target }
  end

  def delete target
    # by index
    if target.class == Fixnum || target =~ /^[0-9]+$/
      delete_by_index target.to_i
    elsif target.class == Hash
      delete_by_reference target
    elsif target.class == String
      delete_by_target target
    else
      throw "Passed unsupported type to Reaction#delete:  "+target.inspect
    end
  end

  def delete_by_target target
    return unless reactions = find_all(target)
    reactions.each { |reaction| @reactions.delete(reaction) }
  end

  def delete_by_reference reference
    @reactions.delete(reference)
  end

  def delete_by_index index
    delete_by_reference @reactions[index.to_i]
  end

  def targets
    @reactions.map{|reaction|reaction[:target]}.uniq.sort
  end

  def chance_play chance, random=nil
    random = rand(100) if random.nil?
    chance = chance.to_i
    return true  if chance == 100
    return false if chance == 0
    return true  if random < chance
    false
  end

end
