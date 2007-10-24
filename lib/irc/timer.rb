class Irc::Timer
  def initialize
    @timers = []
  end
  def delete timer
    @timers.delete timer
  end
  def add(interval,&block)
    timer = EM::PeriodicTimer.new(interval){
      block.call
    }
    @timers << timer
    timer
  end
  def add_ounce(period,&block)
    timer = EM::Timer.new(period){
      block.call
    }
    @timers << timer
    timer
  end
end
