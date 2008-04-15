class FloodControl < Meth::Plugin
  def post_init
    @logs = Hash.new{|h,k|h[k]={
      :last => 0, # last time of offense
      :count => 0,  # how many times they are offending
      :kicked => 0
    }}
  end
  def incoming m
    return if m.personal
    user = m.source.nick.downcase
    log  = @logs[user]
    # within 2 seconds
    if (m.time - log[:last]).to_i < 2
      log[:count] += 1
      if log[:count] > 6
        @bot.send_data "KICK #{m.channel.name} #{m.source.nick}\n"
        m.reply "#{user} has been kicked for flooding..."
        log[:kicked] += 1
        if log[:kicked] >= 3
          # ban user
          @bot.send_data "MODE #{m.channel.name} +b #{m.source.nick}\n"
          m.reply "#{m.source.nick} has been banned from channel..."
          m.reply_directory "You have been banned from #{m.channel.name}"+
                            "Contact channel owner to be removed..."
        else
          m.reply_directly "You have been kicked for flooding..."+
                           "You have 3 strikes before your banned..."
        end
      elsif log[:count] == 4
        m.reply "#{user} I'm going to kick you!"
      elsif log[:count] == 2
        m.reply "#{user} slow down you are spamming..."
      end
    else
      log[:count] = 0
    end
    log[:last] = m.time
  end
  def notice m
    incoming m
  end
  def privmsg m
    incoming m
  end
end
