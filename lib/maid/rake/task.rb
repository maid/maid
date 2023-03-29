require 'rake'
require 'rake/tasklib'

module Maid
  module Rake
    class Task < ::Rake::TaskLib
      DEFAULT_DESCRIPTION = 'Maid Task'

      def initialize(*args, &task)
        @args      = args
        @task_proc = task
        define
      end

      private

      attr_reader :task_proc

      def args
        @args.reject(&:empty?)
      end

      def task_description
        @task_description ||= begin
          opts = args.detect { |arg| arg.is_a?(Hash) }
          (opts && opts.delete(:description)) || DEFAULT_DESCRIPTION
        end
      end

      def define
        desc task_description
        task(*args) do |task|
          SingleRule.perform(task.name, task_proc)
        end
      end
    end
  end
end
