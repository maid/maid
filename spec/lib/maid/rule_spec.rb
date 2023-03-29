require 'spec_helper'

module Maid
  describe Rule do
    it 'is able to be followed' do
      rule = Rule.new('my rule', -> { 1 + 2 })
      expect(rule.follow).to eq(3)
    end
  end
end
