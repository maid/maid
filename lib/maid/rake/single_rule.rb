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
        maid_instance.rule name do
          maid_instance.instance_eval(&task)
        end
        self
      end
    end
  end
end
