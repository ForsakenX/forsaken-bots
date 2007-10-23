class Primes < Meth::Plugin
  def initialize *args
    super *args
    @bot.command_manager.register("primes",self)
  end
  def help m=nil
    "primes [<start>-]<finish> => "+
    "Return a list of prime numbers from <start> to <finish>. "+
    "If <start> is ommited then it defaults to '2'."
  end
  def command m
    @m = m
    input = m.params.shift
    unless input =~ /^([0-9]+-)*[0-9]+$/
      m.reply "Invalid argument\n"+help
      return
    end
    if input =~ /-/
      input =~ /^([0-9]*)-([0-9]*)/
      range = ($1.to_i..$2.to_i)
    else
      range = (2..input.to_i)
    end
    #m.reply "Range set to: #{range}"
    primes(range)
  end
  def primes(range)
    # start time
    start = Time.now;
    # holds list of found elements
    found=[]
    # for each number in the range
    found = range.select{|n|
      # holds list of numbers
      # which did not devide cleanly
 #     rejected=[]
      # from 2 up to the sqaure root of the number
      # try to see if its a prime
      (2..Math.sqrt(n)).each{|i|
        # if number can be divided by any rejected number cleanly
        # then this number cannot be a prime either
 #       result = false
 #       rejected.each{|r|
 #         break if r > Math.sqrt(i)
 #         result = ((i%r)==0)
 #       }
 #       next if result
        # if this number cleanly devides
        if ((n%i)==0)
          found << n
          break
        end
        # store non clean devided numbers
 #       rejected << i
      }
    }
    @m.reply "Found #{found.length} primes within range #{range} "+
             "in #{(Time.now-start)} seconds "
  end
end


