#!/usr/bin/ruby -rubygems

require 'test/unit'


#
# This test is skipped if we cannot load the rubocop-gem.
#
class TestRubocop < Test::Unit::TestCase

  def setup
  end

  def teardown
  end

  def test_code
    begin
      require 'rubocop'

      cli = RuboCop::CLI.new
      result = cli.run
      assert(result == 0, 'No errors found')

    rescue LoadError => ex
      skip("Failed to load 'rubocop' gem - skipping")
    end
  end

end
