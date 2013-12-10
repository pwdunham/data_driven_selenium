#-----------------------------------------------------------------------------#

#
#-----------------------------------------------------------------------------#
require "rubygems"
require "test/unit" #for test cases

require "selenium-webdriver"
require 'json'
require 'pp'

$LOAD_PATH << File.dirname(__FILE__)
$selected_company = ARGV[0]
require 'browser_functions'  #json_contents = File.read('company_input.json')
#$selected_company = $args[0]

#
def setup()
  json_contents = File.read('company_input.json')
  puts "the client is #{$selected_company}"
  parsed_data = JSON.parse(json_contents)
  puts "parsed data"
  puts parsed_data["clients"]["#{$selected_company}"]['env']
  $env = parsed_data["clients"][$selected_company]['env']
  puts "env = #{$env}"
#  require 'browser_functions'  #json_contents = File.read('company_input.json')

end

#$environment =$args[0]
#$selected_company = $args[0]
#$browser = $args[2].to_sym
#get_test_data(company)
#parsed_data = JSON.parse(json_contents)
#puts parsed_data["clients"]["#{company}"]['env']
#env = parsed_data["clients"]["#{company}"]['env']
#puts "the env is #{env}"

#driver = Selenium::WebDriver.for :firefox

#Loading the Company URL
if $env == 'prod'
  test_url ="#{$selected_company}.jibeapply.com"
  puts "test url is #{test_url}"
else
  test_url ="#{$selected_company}.#{$env}.jibeapply.com"
  puts "test url is #{test_url}"
end
#@driver.get "http://#{test_url}"
#
#@driver.navigate.refresh

#driver.navigate.to test_url
abort("end")

#$test_site = setupInfo["URL"]
#$username = setupInfo["User"]
#$password = setupInfo["Password"]

#get today's date for use in later scripts
$today = Time.now.month.to_s + "/" + Time.now.day.to_s + "/" + Time.now.year.to_s

# open an IE browser
#$ie = Watir::IE.new
#$ie.speed = :zippy #available in Watir 1.5.6, for older versions use :fast
##  go to the selected URL
#$ie.goto($test_site)

class TestSuite < Test::Unit::TestCase
  require 'ci/reporter/rake/test_unit_loader' #ci_reporter for generating xml reports, if you don't want to use ci_reporter, delete this line
  include Watir::Assertions

  #test cases are run alphabetically, no matter how they are ordered here
  #you can use any naming convention you like, as long as it's in alphabetical order
  #these test case names will be the headers for the ci_reporter xml report
  def test00_login
    if $runTests["loginUser"] == "Yes"
      login($username, $password)
    else
      puts " "
      puts "You chose not to run the login test."
    end
  end

  def test01_createAccounts
    if $runTests["createAccounts"] == "Yes"
      createAccounts($accounts)
    else
      puts " "
      puts "You chose not to run the Create Accounts tests."
    end
  end

  def test02_dataVerification
    if $runTests["dataVerification"] == "Yes"
      dataVerification($accounts)
    else
      puts " "
      puts "You chose not to run the Data Verification tests."
    end
  end

  def test03_logout
    if $runTests["logout"] == "Yes"
      logout
    else
      puts " "
      puts "You chose not to run the logout test."
    end
  end

end