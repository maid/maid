require 'spec_helper'

describe Maid::NumericExtensions::Time, '#since?' do
  it 'tells you that 1 week ago happened after 2 weeks ago' do
    expect(1.week.since?(2.weeks.ago)).to be(true)
  end

  it 'tells you that 2 weeks ago was not after 1 week ago' do
    expect(2.week.since?(1.weeks.ago)).to be(false)
  end
end

describe Maid::NumericExtensions::SizeToKb do
  it 'tells you that 1 megabyte equals 1024 kilobytes' do
    expect(1.megabyte).to eq(1024.kilobytes)
  end

  it 'tells you that 1 gigabyte equals 1024 megabytes' do
    expect(1.gigabyte).to eq(1024.megabytes)
  end

  it 'tells you that 1 terabyte equals 1024 gigabytes' do
    expect(1.terabyte).to eq(1024.gigabytes)
  end
end
