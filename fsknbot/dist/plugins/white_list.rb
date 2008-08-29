class WhiteList < Meth::Plugin
  def pre_init
    @commands = [:whitelist]
  end
  def whitelist m
    m.reply "The whitelist has been messaged to you."
    m.reply_directly users.join(', ')
  end
  def users
    %w{silence methods bully bdb badsector
       diii-The_Lion robocat amgoz1 chanserv
       chosen crusty don epsy frostbite4 fskn_horny
       kmiell krez ntrek reptile speedytr stealthmantle
       trinityx wizzard }
  end
  def include? user
    users.include? user.downcase
  end
end
