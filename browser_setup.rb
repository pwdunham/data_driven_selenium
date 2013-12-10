require "rubygems"
require "test/unit" #for test cases

require "selenium-webdriver"
require 'json'
require 'pp'

class BrowserSetup < Test::Unit::TestCase
  include Test::Unit::Assertions
  extend Test::Unit::Assertions
  #  attr_accessor :browser, :test_data, :answer_json, :driver, :wait, :wait_less, :wait_more, :verification_errors
  #  browser = :firefox
  def initialize(browser = :firefox)
    # @server = server
    @browser = browser
    @test_data = get_test_data
    @answer_json=Array.new
    setup
  end

  def setup()
    json_contents = File.read('company_input.json')
    puts "the client is #{$company}"
    parsed_data = JSON.parse(json_contents)
    puts parsed_data["clients"]["#{$company}"]['env']
    $env = parsed_data["clients"][$company]['env']
    puts "the env is #{$env}"
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
      #@driver = Selenium::WebDriver.for(:remote, :url => @sel_grid_url, :desired_capabilities => @browser, :http_client => client)

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

    # @server = server
    #    @browser = browser
    #    @test_data = get_test_data
    #    @answer_json=Array.new
    #    @driver = Selenium::WebDriver.for :firefox
  end

  #Loading the Company URL
  #  if env == 'prod'
  #    test_url ="#{company}.jibeapply.com"
  #    puts "test url is #{test_url}"
  #  else
  #    test_url ="#{company}.#{env}.jibeapply.com"
  #    puts "test url is #{test_url}"
  #  end
  #
  #  driver.navigate.to test_url
end

