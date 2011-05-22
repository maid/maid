require 'spec_helper'

describe Maid do
  it 'should include Maid::NumericExtensions' do
    1.minute.should == 60
  end
end

describe Maid, '.rules' do
  it 'should run in the context of Tools' do
    Maid::Tools.should_receive(:class_eval)
    Maid.rules { 'rule block' }
  end
end
