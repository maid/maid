require 'spec_helper'

describe Maid do
  it 'should include Maid::NumericExtensions::Time' do
    1.minute.should == 60
  end
  it 'should include Maid::NumericExtensions::SizeToKb' do
    1.megabyte.should == 1024
  end
end

describe Maid, '.with_instance' do
  it 'should temporarily set the instance to the given argument and execute the block' do
    instance = mock('instance')
    Maid.with_instance(instance) { 0 }.should == 0
    Maid.instance_eval { @instance }.should be_nil
  end
end

describe Maid, '.rules' do
  it 'should run in the context of the Maid::Maid instance' do
    instance = mock('instance')
    instance.should_receive(:foo)

    Maid.with_instance(instance) do
      Maid.rules { foo }
    end
  end
end
