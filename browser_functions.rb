# encoding: utf-8
require 'rubygems'

gem 'test-unit'
require "test/unit"
require 'test/unit/ui/console/testrunner'
require 'httmultiparty'
require "json"
require 'rake'
require 'deathbycaptcha'


require 'rake'
require 'ci/reporter/rake/test_unit'
require 'ci/reporter/rake/test_unit_loader'
require 'ap'
require 'uri'
require "rubygems"
require "test/unit" #for test cases

require "selenium-webdriver"

#require 'json'
require 'pp'

#$environment =$args[0]
#$browser = $args[2].to_sym

class BrowserSetup 
  include Test::Unit::Assertions
  extend Test::Unit::Assertions


  attr_accessor :browser, :test_data, :answer_json, :driver, :wait, :wait_less, :wait_more, :verification_errors

  def initialize(browser = :firefox)
    # @server = server
    @browser = browser
    @test_data = get_test_data
    @answer_json=Array.new

    if ENV['HEADLESS'].nil? or ENV['HEADLESS'].downcase != "false"
      puts "Launching in headless mode"
      require 'headless'
      headless = Headless.new
      headless.start
    end
    if $browser ==  :firefox

      @driver = Selenium::WebDriver.for :firefox

      client = Selenium::WebDriver::Remote::Http::Default.new
      client.timeout = 120

    elsif $browser == :chrome

      client = Selenium::WebDriver::Remote::Http::Default.new
      client.timeout = 120
      profile = Selenium::WebDriver::Chrome::Profile.new
      profile['profile.managed_default_content_settings.geolocation'] = 2
      data = profile.as_json
      caps = Selenium::WebDriver::Remote::Capabilities.chrome
      caps['chromeOptions'] = {
        'profile'    => data['zip'],
        'extensions' => data['extensions']
      }

      @driver = Selenium::WebDriver.for(:remote, :url => @sel_grid_url, :desired_capabilities => caps, :http_client => client)

    else
      puts 'No browser declared'
    end

    # @driver = Selenium::WebDriver.for :chrome

    @client = DeathByCaptcha.http_client('boriskozak@gmail.com', '661351')
    @driver.manage.timeouts.implicit_wait = 30
    @wait_to_fail = Selenium::WebDriver::Wait.new :timeout => 3
    @wait_less = Selenium::WebDriver::Wait.new(:timeout => 15)
    @wait = Selenium::WebDriver::Wait.new(:timeout => 30)
    @wait_more = Selenium::WebDriver::Wait.new(:timeout => 45)
    @wait_much_more = Selenium::WebDriver::Wait.new(:timeout => 60)
    @verification_errors = []

    setup_load =0
    begin
      if $selected_company == "ups"
        @driver.get "http://www.ups.com"
      else
        @driver.get "http://#{$env}"
      end
    rescue
      setup_load=setup_load+1
      retry if setup_load <3
      @driver.save_screenshot("HomePage-#{setup_load}.png")
      raise "Home Page does not load #{$!}"
    end

    @driver.manage.window.resize_to(700, 1000)

  end

  def get_test_data
    json_contents = File.read('company_input.json')
    puts "the client is #{$selected_company}"
    parsed_data = JSON.parse(json_contents)
    puts parsed_data["clients"]["#{$selected_company}"]['env']
    $env = parsed_data["clients"][$selected_company]['env']
    puts "the env is #{$env}"

  end

  def self.shutdown
    puts "\nAll tests are now complete.\nShutting down."
    extend Test::Unit::Assertions
    @@handler.driver.quit
    assert_equal [], @@handler.verification_errors
  end
end

