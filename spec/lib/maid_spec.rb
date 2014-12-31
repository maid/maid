require 'spec_helper'

describe Maid do
  it 'includes Maid::NumericExtensions::Time' do
    expect(1.minute).to eq(60)
  end

  it 'includes Maid::NumericExtensions::SizeToKb' do
    expect(1.megabyte).to eq(1024)
  end
end

describe Maid, '.with_instance' do
  it 'temporarily sets the instance to the given argument and execute the block' do
    instance = double('instance')
    expect(Maid.with_instance(instance) { 0 }).to eq(0)
    expect(Maid.instance_eval { @instance }).to be(nil)
  end
end

describe Maid, '.rules' do
  it 'runs in the context of the Maid::Maid instance' do
    instance = double('instance')
    expect(instance).to receive(:foo)

    Maid.with_instance(instance) do
      Maid.rules { foo }
    end
  end
end
