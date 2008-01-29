require "#{DIST}/lib/spidermonkey"
require "timeout"
class JsEval < Meth::Plugin
  def initialize *args
    super *args
    @bot.command_manager.register("js",self)
    @bot.command_manager.register("jseval",self)
    @bot.command_manager.register("jsinfo",self)
  end
  def help t=nil, s=nil
    "js|jseval <js> => Eval and display return value.  "+
    "jsinfo => Returns details on the JS Engine.  "+
    "Uses Mozilla's SpiderMonkey JS Engine."
  end
  def command m
    case m.command
    when "jsinfo"
      jsinfo m
    when "js","jseval"
      jseval m
    end
  end
  def jsinfo m
    m.reply SpiderMonkey::LIB_VERSION
  end
  def jseval m
    begin
      Timeout.timeout(2) {
        m.reply SpiderMonkey.evalget(m.params.join(' '))
      }
    rescue SpiderMonkey::EvalError
      m.reply "JsError: #{$!.message}"
    rescue Exception
      m.reply "Exception: #{$!}"
      @bot.logger.error "#{$!}\n#{$@.join("\n")}"
    end
  end
end
