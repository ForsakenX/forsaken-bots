
IrcCommandManager.register 'spell' do |m|
  m.reply SpellCommand.run(m)
end

IrcCommandManager.register 'spell',
  "spell <word> => List suggestions for spelling of word."

require 'raspell'
class SpellCommand
  @speller = Aspell.new("en_US")
  @speller.suggestion_mode = Aspell::NORMAL
  def self.run m
    output  = "#{m.args.first}: "
    output += "Looks correct.  Other " if @speller.check(m.args.first)
    output += "Suggestions: "+@speller.suggest(m.args.first).join(', ')
    output
  end
end

