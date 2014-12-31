module Maid
  module Rake
    class SingleRule
      attr_writer :maid_instance
      attr_reader :name, :task

      def initialize(name, task)
        @name = name
        @task = task
      end

      def clean
        maid_instance.clean
      end

      def maid_instance
        @maid_instance ||= ::Maid::Maid.new(rules_path: '/dev/null')
      end

      def define
        maid_instance.rule(name, &task)
        self
      end

      class << self
        def perform(name, task)
          new(name, task).define.clean
        end
      end
    end
  end
end
