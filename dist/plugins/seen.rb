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
    check_user who
    @seen[who][:msg] = "#{m.time.strftime(time_format)} #{m.message}"
    save
  end

  def notice m
    who = m.source.nick.downcase
    check_user who
    @seen[who][:msg] = "#{m.time.strftime(time_format)} (notice) #{m.message}"
    save
  end

  def join m
    who = m.user.nick.downcase
    check_user who
    @seen[who][:ip] = m.user.ip
    @seen[who][:status] = "#{m.time.strftime(time_format)} JOIN #{m.channel.name})"
    save
  end

  def part m
    who = m.user.nick.downcase
    check_user who
    @seen[who][:status] = "#{m.time.strftime(time_format)} PART #{m.channel.name}): #{m.message}"
    save
  end

  def quit m
    who = m.user.nick.downcase
    check_user who
    @seen[who][:status] = "#{m.time.strftime(time_format)} QUIT #{m.message}"
    save
  end

  def time_format
    "(%m/%d/%y - %H:%M:%S)"
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
    m.reply "#{who}'s status: { #{last[:status].to_s} }, "+
            "from: { #{last[:ip].to_s } }, "+
            "last said: { #{last[:msg].to_s} }"
  end

  private
  def save
    file = File.open(@db,'w+')
    YAML.dump(@seen,file)
    file.close
  end

  def check_user who
    return unless @seen[who].nil?
    @seen[who] = {:ip=>"",:msg=>"",:status=>""}
  end

end
