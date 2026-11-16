require 'spec_helper'

describe 'maid.gemspec' do
  it 'loads the description without Maid::SUMMARY' do
    project_root = File.expand_path('..', __dir__)
    script = <<~RUBY
      require 'maid/version'
      Maid.send(:remove_const, :SUMMARY)
      specification = Gem::Specification.load('maid.gemspec')
      expected_description = [
        'Be lazy. Let Maid clean up after you, based on rules you define. ',
        'Think of it as "Hazel for hackers".'
      ].join
      abort unless specification&.description == expected_description
    RUBY

    expect(system(RbConfig.ruby, '-Ilib', '-e', script, chdir: project_root)).to be(true)
  end
end
