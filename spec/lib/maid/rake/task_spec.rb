require 'spec_helper'

module Maid
  module Rake
    describe Task do

      before(:all) { ::Rake::TaskManager.record_task_metadata = true }

      subject(:define_task) { described_class.new *args, &instructions }
      let(:instructions)    { Proc.new {} }

      describe '#initialize' do
        before { ::Rake::Task.clear }

        describe 'task body' do
          let(:args) { :foobar }

          it 'sends given instructions to SingleRule' do
            expect(SingleRule)
              .to receive(:perform)
              .with('foobar', instructions)
            define_task && ::Rake::Task[:foobar].execute
          end
        end

        describe 'task description' do
          context 'given just the task name as argument' do
            let(:args) { [:foobar] }

            it 'defines a rake task with default description' do
              desc = described_class.const_get 'DEFAULT_DESCRIPTION'

              define_task
              expect(::Rake::Task[:foobar].comment).to eq(desc)
            end
          end

          context 'given a description argument' do
            let(:args) { [:foobar, description: 'Custom description'] }

            it 'defines a rake task with the description provided' do
              define_task
              expect(::Rake::Task[:foobar].comment).to eq('Custom description')
            end
          end
        end
      end

    end
  end
end
