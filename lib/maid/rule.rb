class Maid::Rule < Struct.new(:description, :instructions, :maid)
  # Follow the instructions of the rule.
  def follow(*args)
    maid.instance_exec(*args, &instructions)
  end
end
