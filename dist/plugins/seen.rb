class Seen < Meth::Plugin

  def pre_init
    @commands = [:seen,:seenlist]
    @db = File.expand_path("#{BOT}/db/seen.yaml")
    @seen = File.exists?(@db) ? (YAML.load_file(@db)||{}) : {}
  end

  def help m=nil, topic=nil
    "seen <nick> => Shows the last thing <nick> said."
  end

  def privmsg m
    who = m.source.nick.downcase
    @seen[who] = "#{m.time.strftime(format)} Saying: #{m.message}"
    save
  end

  def notice m
    who = m.source.nick.downcase
    @seen[who] = "#{m.time.strftime(format)} Saying: (notice) #{m.message}"
    save
  end

  def join m
    who = m.user.nick.downcase
    @seen[who] = "#{m.time.strftime(format)} Saying: JOIN (#{m.channel.name})"
    save
  end

  def part m
    who = m.user.nick.downcase
    @seen[who] = "#{m.time.strftime(format)} Saying: PART (#{m.channel.name}): #{m.message}"
    save
  end

  def quit m
    who = m.user.nick.downcase
    @seen[who] = "#{m.time.strftime(format)} Saying: QUIT #{m.message}"
    save
  end

  def format
    "(%m/%d/%y) (%H:%M:%S)"
  end

  def seenlist m
    m.reply "A seen list has been messaged to you..."
    m.reply_directly "I have seen the following people: " +
                     @seen.keys.sort.join(', ')
  end

  def seen m
    params = m.params
    who = params.shift
    unless @seen.has_key?(who.downcase)
      m.reply "Sorry, I have never seen #{who}"
      return
    end
    last = @seen[who.downcase]
    m.reply "#{who} was last seen at #{last}"
  end

  private
  def save
    file = File.open(@db,'w+')
    YAML.dump(@seen,file)
    file.close
  end

end
