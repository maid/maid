class Maid::Rule < Struct.new(:description, :instructions, :maid)
  # Follow the instructions of the rule.
  def follow(*)
    maid.instance_exec(*, &instructions)
  end
end
