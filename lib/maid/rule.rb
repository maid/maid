class Maid::Rule < Struct.new(:description, :instructions)
  # Follow the instructions of the rule.
  def follow
    instructions.call
  end
end
