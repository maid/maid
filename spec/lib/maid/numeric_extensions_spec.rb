require 'spec_helper'

describe Maid::NumericExtensions, '#since?' do
  it 'should tell you that 1 week ago happened after 2 weeks ago' do
    (1.week.since? 2.weeks.ago).should be_true
  end

  it 'should tell you that 2 weeks ago was not after 1 week ago' do
    (2.week.since? 1.weeks.ago).should be_false
  end
end
