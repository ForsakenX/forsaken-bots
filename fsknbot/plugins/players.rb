class Players < Meth::Plugin
  def pre_init
    @commands = [:player,:players]
    @db = File.expand_path("${ROOT}/db/players.yaml")
    @players = File.exists?(@db) ? (YAML.load_file(@db)||[]) : []
  end
  def help m=nil, topic=nil
    "players => Return list of players.  "+
    "player add [[player] ...] => Add list of space separated players.  "
  end
  def player m
    unless ['methods','silence'].include?(m.source.nick.downcase)
      m.reply "Sorry, you are not an administrator :["
      return false
    end
    params = m.params.dup
    case params.shift
    when 'add'
      @players << params.map{|p|p.downcase}
      save
      m.reply "Player[s] have been added :]"
    end
  end
  def players m
    if @players.empty?
      m.reply "There are no players :["
      return false
    end
    m.reply "A full list of players has been messaged to you :]"
    m.reply_directly @players.join(', ')
  end
  def save
    file = File.open(@db,'w+')
    YAML.dump(@players,file)
    file.close
  end
end
