class Hangman < Irc::Plugin

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
    def tried? letter
      @guessed.include?(letter) || @found.include?(letter)
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
    h = {
      :start => "hangman start [chances] => Start a new game.  "+
                "Optionally set the # of [chances] (default is 10).",
      :try   => "hangman try <letter> => Try a letter.",
      :complete => "hangman complete <word> => Try to guess the entire word.",
      :info  => "hangman [info|status] => Print current game status.",
      :short => "Valid options are start|try|info|status."+
                "help hangman <option> for specific help."
    }
    _alias = {
      :status => :info
    }
    return [:start,:try,:info].map{|n|h[n]}.join(',  ') if topic.nil?
    return h[topic.to_sym] if h.has_key?(topic.to_sym)
    return h[_alias[topic.to_sym]] if _alias.has_key?(topic.to_sym)
  end

  def command m
    params = m.params.dup
    option = params.shift
    # there is no game in process
    if @game.nil?
      process_option_no_game(m, option, params)
    # there is a game in process
    else
      process_option_in_game(m, option, params)
    end
  end

  def process_option_no_game m, option, params
    case option

    # start a game
    when "start","",nil # default
      start m, params

    # try a letter
    when "try"
      m.reply "You havn't started a game!  "+
              "Usage: "+help(m,:start)

    # print info|status on game
    when "status","info"
        m.reply "you are not playing..."

    # unkonwn option
    else 
      m.reply "I don't recognize that option!  "+
              "Usage: "+ help(m,:short)
    end
  end

  def process_option_in_game m, option, params
    case option

    # start a game
    when "start"
      m.reply "A game is already started..."

    # print info|status on game
    when "status","info","",nil # default
      m.reply info

    # try a letter 
    when "try"
      try m, params

    # unkonwn option
    else 
      m.reply "I don't recognize that option!  "+
              "Usage: "+ help(m,:short)
    end
  end

  def start m, params

    # check if [chances] passed
    if chances = params.shift
      unless chances =~ /^[0-9]+$/
        m.reply "Sorry '#{chances}' isn't a valid option.  "+
                "Usage: "+help(m,:start)
        return
      else
        chances = chances.to_i
      end
      responses = \
      ["Whats the point of playing?",
       "Thats just no fun now is it?",
       "Your selfish....",
       "I'm telling momy",
       "Play nice or hit the dice",
       "Give me a number like that again, "+
         "and I'm knocking your teath out...",
       "Do I look like I have hairy tits?",
       "You call that a game?"]
      if chances < 1 || chances > 45
        m.reply responses[rand(responses.length-1)]
        return
      end
    end

    # start game
    @game = Game.new(chances||10) # default 10

    #
    m.reply "Game started!  "+
            "Start guessing letters, example usage: "+
            "hangman try a.  #{@game.mask}"

  end

  def try m, params
    unless letter = params.shift
      m.reply "Give me a letter please...  "+
              "Usage:  #{help(m,:try)}  "+
              info
      return
    end
    unless letter.length < 2
      m.reply "One letter at a time please...  "+info
      return
    end
    if @game.tried?(letter)
      m.reply "You already tried that letter!  "+info
      return
    end
    if @game.try(letter)
      if @game.won
        m.reply "You won!  #{@game.mask}"
        @game = nil
      else
        m.reply "Good job! Keep trying! "+info
      end
    else
      if @game.lost
        m.reply "You lost!  "+
                "The word was: #{@game.word}"
        @game = nil
      else
        m.reply "Bad choice!  " + info
      end
    end
  end

  def info
    "You have #{@game.mask.count('_')} characters to go!  "+
    "And #{@game.chances} chances left!  "+
    "Guessed: #{@game.guessed.join(', ')}.  "+
    "Found: #{@game.found.join(', ')}.  "+
    "#{@game.mask}"
  end

end
