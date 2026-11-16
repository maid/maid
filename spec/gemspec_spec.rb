require 'spec_helper'

describe Gem::Specification do
  let(:script) do
    <<~RUBY
      require 'maid/version'
      Maid.send(:remove_const, :SUMMARY)
      specification = Gem::Specification.load('maid.gemspec')
      expected_description = [
        'Be lazy. Let Maid clean up after you, based on rules you define. ',
        'Think of it as "Hazel for hackers".'
      ].join
      abort unless specification&.description == expected_description
    RUBY
  end

  it 'loads the description without Maid::SUMMARY' do
    project_root = File.expand_path('..', __dir__)
    expect(system(RbConfig.ruby, '-Ilib', '-e', script, chdir: project_root)).to be(true)
  end
end
