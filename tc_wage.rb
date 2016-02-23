#!/usr/bin/env ruby
# File: tc_wage.rb

require_relative "wage.rb"
require "test/unit"

class TestTax < Test::Unit::TestCase

  def test_get_band_id
    t = Tax.new [[:none, 0, 0]] 
    assert_equal 0, t.get_band_id(0)
    assert_raise(WageError) { t.get_band_id(1) }
  end

  def test_get_band
    t = Tax.new [[:one, 100, 0], [:two, 200, 0]]
    assert_equal :one, t.get_band(0)
    assert_equal :two, t.get_band(101)
    assert_raise(WageError) { t.get_band(201) }
  end

  def test_get_rate
    t = Tax.new [[:one, 100, 1], [:two, 200, 10]]
    assert_equal 1, t.get_rate(40)
    assert_equal 10, t.get_rate(199)
  end
end
