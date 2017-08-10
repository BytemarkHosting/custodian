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
      assert(result.zero?, 'No errors found')

    rescue LoadError => ex
      if methods.include?(:skip)
        skip("Failed to load 'rubocop' gem - skipping")
      else
        omit("Failed to load 'rubocop' gem - skipping")
      end
    end
  end

end
