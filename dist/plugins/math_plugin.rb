class MathPlugin < Meth::Plugin
  @@supported = %w{ 1-9 % * + - \ ( ) . }
  def initialize *args
    super *args
    @bot.command_manager.register('math',self)
  end
  def help m=nil,topic=nil
    h = {
      :help => "math <expression> => Evaluates <expression>.",
      :characters => "Supported characters: #{@@supported.join(', ')}"
    }
    return h[topic] if h.has_key?(topic)
    "#{h[:help]} #{h[:characters]}"
  end
  def command m
    expr = m.params.join(' ')
    if dirty? expr
      m.reply "Message contains unsupported characters: "+help(m,:characters)
      return
    end
    begin
      result = eval(expr)
    rescue Exception => e
      m.reply "There was an error in your expression."
      return
    end
    m.reply "#{expr} = #{result}"
  end
  def dirty? str
    not clean(str)
  end
  def clean str
    str =~ /[1-9%\*\+\-\/\(\)\. ]+/
  end
end
