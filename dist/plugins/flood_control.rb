class FloodControl < Meth::Bot
  def post_init
    @logs = Hash.new{|h,k|h[k]={
      :start => 0, # start time of offense
      :count => 0  # how many times they are offending
    }}
  end
  def incoming m
    user = m.source.nick.downcase
    log  = @logs[user]
    if m.time < log[:start]+1
      # offending
      log[:count] += 1
      if log[:count] > 8
        @bot.send_data "KICK #{m.channel.name} #{m.source.nick}"
      elsif log[:count] > 5
        m.reply "#{user} slow down you are spamming..."
      end
    end
  end
  def notice m
    incoming m
  end
  def privmsg m
    incoming m
  end
end
