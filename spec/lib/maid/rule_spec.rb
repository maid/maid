require 'spec_helper'

module Maid
  describe Rule do
    it 'should be able to be followed' do
      rule = Rule.new 'my rule', lambda { 1 + 2 } 
      rule.follow.should == 3
    end
  end
end
