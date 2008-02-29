require 'cgi'
class ChannelLogger < Meth::Plugin
  # setup shit
  def pre_init
    @commands = [:logs]
    @url = "http://chino.homelinux.org/~daquino/forsaken/logs"
    @log_dir = "#{BOT}/db/channel_logs"
    mkdir @log_dir
    @channels = {}
    # catch messages we send
    @sent_proc = Proc.new{|line|sent line}
    @bot.event.register('irc.send_data',@sent_proc)
  end
  # before reload
  def cleanup *args
    super *args
    @channels.each do |f|
      f.close
    end
    @bot.event.unregister('irc.send_data',@sent_proc)
  end
  # help
  def help m=nil, topic=nil
    "logs => Path to logs for this channel.  "+
    "logs today => Path to log file for today."
  end
  # command to return url for logs
  def logs m
    pound = CGI.escape("#")
    channel = m.channel.name.downcase
    channel_path = "#{@url}/#{channel}"
    case m.params[0]
    when "today"
      path = Time.now.strftime("%Y/%m-%Y/#{channel}-%m-%d-%Y")
      m.reply "#{channel_path}/#{path}".gsub('#',pound)
    else
      m.reply channel_path.gsub('#',pound)
    end
  end
  # detect joins and setup directory
  def join m
    m.reply "I joined!!!" \
      if m.user.nick.downcase == @bot.nick.downcase
    return unless m.user.nick.downcase == @bot.nick.downcase
    m.reply "Someone Joined!"
    mkdir "#{@log_dir}/#{m.channel.name.downcase}"
  end
  # catch and format privmsg
  def privmsg m
    return if m.personal
    message = "(#{m.time.strftime("%H:%M:%S")}) "+
              "#{m.source.nick}: "+
              "#{m.message}\n"
    log_message(m.channel.name.downcase, m.time, message)
  end
  # catch and format message we send
  def sent line
    return if line.nil?
    line = line.dup
    return if line.slice!(/^PRIVMSG /i).nil?
    return unless line =~ /^#([^ ]+) :([^\n]+)/
    channel,message = "##{$1}",$2
    time = Time.now
    message = "(#{time.strftime("%H:%M:%S")}) "+
              "#{@bot.nick}: "+
              "#{message}\n"
    log_message(channel, time, message)
  end
  # log the message
  def log_message channel, time, message
    f = file(channel,time)
    f.write(message)
    f.flush
  end
  # return or open new file handler
  def file channel, time
    channel = channel.downcase
    mkdir "#{@log_dir}/#{channel}"
    file = @channels[channel]
    date = time.strftime("%m-%d-%Y")
    filename = "#{channel}-#{date}"
    if file.nil? || File.basename(file.path) != filename
      file.close unless file.nil?
      year = time.strftime("%Y")
      month = time.strftime("%m-%Y")
      dir_path = "#{@log_dir}/#{channel}/#{year}/#{month}"
      mkdir dir_path
      full_path = "#{dir_path}/#{filename}"
      file = File.open(full_path,"a+")
      channel = file
    end
    file
  end
  # create directory heiarchy
  def mkdir path
    parts = path.split('/')
    parts.each_with_index do |dir,i|
      p = parts[0..i].join('/')
      next if FileTest.exists?(p)
      Dir.mkdir p
    end
  end
end



