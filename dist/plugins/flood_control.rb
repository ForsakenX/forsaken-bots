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
    @m    = m
    @user = @m.source.nick.downcase
    @log  = @logs[@user]
    if (@m.time - @log[:last]).to_i < 2 # within 2 seconds
      defend
    else
      @log[:count] = 0
    end
    @log[:last] = @m.time
  end
  def defend
      @log[:count] += 1
      case @log[:count]
      when 7
        @bot.kick @m.channel, @m.source
        @m.reply "#{@user} has been kicked for flooding..."
        @log[:kicked] += 1
        if !plugins['white_list'].include?(@m.source.nick) &&
          @log[:kicked] >= 3
          # ban user
          @bot.send_data "MODE #{@m.channel.name} +b #{@m.source.nick}\n"
          @m.reply "#{@m.source.nick} has been banned from channel..."
          @m.reply_directory "You have been banned from #{@m.channel.name}"+
                            "Contact channel owner to be removed..."
        else
          @m.reply_directly "You have been kicked for flooding..."+
                           "You have 3 strikes before your banned..."
        end
      when 3,5
        @m.reply "#{@user}: #{warning}"
      end
  end
  def warning
    warnings = [
      "Dude give the enter button a rest...",
      "stfu...",
      "Dude we love you but get a life...",
      "Keep it up and your getting kicked!",
      "slow down spammer...",
      "Your seriously annoying...",
      "Ever heard of the enter key?",
      "Do you know what a period is?",
      "Dude give us a break!",
      "I have detected a moron...",
      "Enough already!",
    ]
    count = 0
    while (i=rand(warnings.length)) != @last
      count += 1
      break if count > 3
    end
    @last = i
    warnings[i]
  end
  def notice m
    incoming m
  end
  def privmsg m
    incoming m
  end
end
