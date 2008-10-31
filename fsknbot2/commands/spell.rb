
IrcCommandManager.register 'spell' do |m|
  m.reply SpellCommand.run(m.args.first.downcase)
end

IrcCommandManager.register 'spell',
  "spell <word> => List suggestions for spelling of word."

require 'raspell'
class SpellCommand
  @speller = Aspell.new("en_US")
  @speller.suggestion_mode = Aspell::NORMAL
  def self.run word
    output  = "#{word}: "
    output += "Looks correct.  Other " if @speller.check(word)
    output += "Suggestions: "+@speller.suggest(word).join(', ')
    output
  end
end

