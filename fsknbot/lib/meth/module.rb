module Module
  def alias_methods new, targets
    targets.each { |target| alias_method new, target }
  end
end
