$:.unshift '.'
require 'rubygems'

gem 'test-unit'
require "test/unit"
require 'test/unit/ui/console/testrunner'
require "selenium-webdriver"
require "httparty"
require "json"

$args = ARGV.dup
#require 'browser_functions'
#require 'testfunctions'

class TestHarness < Test::Unit::TestCase
  def self.startup
    puts "\nLaunching #{$browser} browser ...\n"
    @@handler = BrowserSetup.new($browser)
    puts "The tests will now begin.\n"
    @@handler.get_test_data
  end

  def self.shutdown
    puts "\nAll tests are now complete.\nShutting down."
    extend Test::Unit::Assertions
    @@handler.driver.quit
    assert_equal [], @@handler.verification_errors
  end

end
