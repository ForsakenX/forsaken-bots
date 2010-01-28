class EM::Connection
  def status msg
    puts "--- #{self.class.name}: #{msg}"
  end
end
