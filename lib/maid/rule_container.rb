module Maid::RuleContainer
  include ::Maid::Tools
  attr_reader :rules

  # initialize_rules
  def initialize_rules(&rules)
    @rules ||= []
    instance_exec(&rules)
  end

  # Register a rule with a description and instructions (lambda function).
  def rule(description, &instructions)
    @rules << ::Maid::Rule.new(description, instructions, @maid || self)
  end

  # Follow all registered rules.
  def follow_rules(*args)
    @rules.each do |rule|
      @logger.info("Rule: #{ rule.description }") unless @logger.nil?
      rule.follow(*args)
    end
  end
end
