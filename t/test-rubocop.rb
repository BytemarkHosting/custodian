#!/usr/bin/ruby -rubygems

require 'test/unit'


#
#  Skip this test if we cannot load the gem.
#
begin
  require 'rubocop'
rescue LoadError => ex
  puts "Failed to load 'rubocop' gem - skipping"
  exit(0)
end


class TestRubocop < Test::Unit::TestCase

  def setup
  end

  def teardown
  end

  def test_code
    cli = RuboCop::CLI.new
    result = cli.run
    assert(result == 0, 'No errors found')
  end

end
