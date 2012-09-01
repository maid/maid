module Maid
  autoload :App, 'maid/app'
  autoload :Maid, 'maid/maid'
  autoload :Tools, 'maid/tools'
  autoload :NumericExtensions, 'maid/numeric_extensions'
  autoload :Rule, 'maid/rule'
  autoload :VERSION, 'maid/version'

  class << self
    def user_agent
      # Many Linux distributions contain information about the distribution and the version in this file...
      issue_path = '/etc/issue'

      # ...but it doesn't always exist, and isn't part of all Unix like OSes (e.g., Mac OS X).
      if File.exists?(issue_path)
        # Little known Rubyism: `issue` will become `nil` in the `else` case because of variable hoisting.
        issue = File.read(issue_path).strip
      end

      "Maid/#{VERSION} (#{RUBY_PLATFORM} #{issue}) ruby/#{RUBY_VERSION}"
    end

    # Execute the block with the Maid instance set to <tt>instance</tt>.
    def with_instance(instance)
      @instance = instance
      result = yield
      @instance = nil
      result
    end

    # Define rules for the Maid instance.
    def rules(&block)
      @instance.instance_eval(&block)
    end
  end
end

class Numeric
  include Maid::NumericExtensions
end

# TODO Is there a no-conflict way of including the extensions?
