require 'rubygems'
require 'raspell'
class Spell < Meth::Plugin
  def initialize *args
    super *args
    @bot.command_manager.register('spell',self)
    @speller = Aspell.new("en_US")
    @speller.suggestion_mode = Aspell::NORMAL
  end
  def help(m=nil, topic=nil)
    "spell <word> => List suggestions for spelling of word."
  end
  def command m
    word = m.params[0]
    reply  = "#{word}: "
    reply += "Looks correct.  Other " if @speller.check(word)
    reply += "Suggestions: "+@speller.suggest(word).join(', ')
    m.reply reply
  end
end
