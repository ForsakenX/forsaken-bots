class Shutdown < Meth::Plugin
  def pre_init
    @commands = [ :shutdown ]
    @help = "Shutdown => Shuts the bot down."
  end
  def shutdown m
    @m = m
    unless authorized?(m.command,m.source)
      m.reply "You are not an authorized user..."
      return false
    end
#    @bot.send_data "QUIT :Admin shut down...\n"
  end
  def authorized?(command,_user)
    # list of authorizations for commands
    authorizations= {
      :shutdown => [
        {
          :@nick => "methods",
          :ip    => "test"#"68.36.237.152"
        }
      ]
    }
    # no authorizations for command
    # default allow
    return true unless users = authorizations[command.to_sym]
    # check allowed list
    authorized = users.detect { |user|
      # check if allowed entry matches this user
      user.each do |key,val|
        # must respond to allowed key and have same value
        next false unless _respond_to?(_user,(key)) &&
                          _get(_user,key) == val
      end
      # passed
      true
    }
    authorized
  end
  def _get(obj,key)
    if obj.instance_variable_defined?(key.to_sym)
      obj.instance_variable_get(key.to_sym)
    elsif obj.methods.defined?(key.to_s)
      obj.send(key.to_sym)
    else
      throw "Should call _respond_to? first..."
    end
  end
  def _respond_to?(obj,key)
    begin
      return true if obj.instance_variable_defined?(key.to_sym)
      return true if obj.methods.defined?(key.to_s)
    rescue Exception
      false
    end
    false
  end
end
