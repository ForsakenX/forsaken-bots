class Hangman < Meth::Plugin

  class Game
    attr_reader :word, :found, :guessed, :chances
    def initialize(chances)
      words = File.read("/usr/share/dict/words").split("\n")
      @word    = words[rand(words.length)]
      @found   = []
      @guessed = []
      @chances = chances
    end
    def try letter
      # not found
      if @word.index(letter).nil?
        @guessed << letter unless @guessed.include?(letter)
        @chances -= 1
        return false
      end
      # good
      @found << letter
      true
    end
    # mask representing results
    def mask
      mask = @word.dup
      mask.split('').each do |char|
        next if @found.include?(char)
        mask.gsub!(char,'_')
      end
      mask.split('').join(' ')
    end
    def lost
      return false if @chances > 0
      !won
    end
    def won
      return false if @chances < 1
      mask.count('_') == 0
    end
  end

  def initialize *args
    super *args
    @bot.command_manager.register("hangman",self)
  end

  def help(m=nil, topic=nil)
    "hangman start [chances] => start a game.  "+
             "Optionally set the number of [chances].  "+
             "Must be a number, default is 10.  "+
    "hangman try <letter> => Try a letter.  "+
    "hangman guessed => List tried letters.  "+
    "hangman found => List found letters.  "
#    "hangman stop => stop current game.  "+
  end

  def command m
    case m.params.shift
    #
    when "start","",nil # default
      if @game
        m.reply "A game is already started..."
      else
        if arg = m.params.shift
          chances = arg.to_i
          if chances == 0
            m.reply "Sorry '#{arg}' isn't a valid option.  "+
                    "Usage: "+help
            return
          end
        end
        @game = Game.new(chances||10) # default 10
        m.reply "Game started!  Start guessing letters, example usage: hangman try a.  #{@game.mask}"
        #m.reply "The word is #{@game.word}"
      end
    #
#    when "stop"
#      m.reply "Game stopped, answer was: #{@game.word}"
#      @game = nil
    #
    when "try"
      unless @game
        m.reply "You havn't started a game!  "+
                "Usage: "+help
        return
      end
      unless letter = m.params.shift
        m.reply "Give me a letter please...  "+
                "Usage:  "+help
        return
      end
      unless letter.length < 2
        m.reply "One letter at a time please..."
        return
      end
      if @game.guessed.include?(letter) ||
         @game.found.include?(letter)
        m.reply "You already tried that letter!  "+
                "Guessed: #{@game.guessed.join(', ')}.  "+
                "Found: #{@game.found.join(', ')}.  "
        return
      end
      if @game.try(letter)
        if @game.won
          m.reply "You won!  #{@game.mask}"
          @game = nil
        else
          m.reply "Good job!  "+
                  "Keep trying!  "+
                  "You have #{@game.mask.count('_')} characters to go!  "+
                  "And #{@game.chances} chances left!  "+
                  "Guessed: #{@game.guessed.join(', ')}.  "+
                  "Found: #{@game.found.join(', ')}.  "
                  "#{@game.mask}"
        end
      else
        if @game.lost
          m.reply "You lost!  "+
                  "The word was: #{@game.word}"
          @game = nil
        else
          m.reply "Bad choice!  "+
                  "You have #{@game.mask.count('_')} characters to go!  "+
                  "And #{@game.chances} chances left!  "+
                  "#{@game.mask}"
        end
      end
    #
    when "guessed"
      unless @game
        m.reply "You havn't started a game yet!  "+
                "Usage: "+help
        return
      end
      if @game.guessed.length < 1
        m.reply "You haven't tried any letters yet!"
      else
        m.reply @game.guessed.join(', ')
      end
    #
    when "found"
      unless @game
        m.reply "You havn't started a game yet!  "+
                "Usage: "+help
        return
      end
      if @game.found.length < 1
        m.reply "You haven't found any letters yet!"
      else
        m.reply @game.found.join(', ')
      end
    #
    else # unkonwn option
      m.reply "I don't recognize that option!  "+
              "Usage: "+ help
    end
  end

end
