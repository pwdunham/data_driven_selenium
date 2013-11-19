#-----------------------------------------------------------------------------#

#
#-----------------------------------------------------------------------------#
require "rubygems"
require "test/unit" #for test cases
require "selenium-webdriver"
require 'json'
require 'pp'
json_contents = File.read('company_input.json')

company = ARGV[0]
parsed_data = JSON.parse(json_contents)
puts parsed_data['clients'][company]['env']
puts parsed_data['clients'][company]['version']

driver = Selenium::WebDriver.for :firefox

#Loading the Company URL
env ="#{company}.staging.jibeapply.com"
driver.navigate.to env
puts "env = " + $env

$test_site = setupInfo["URL"]
$username = setupInfo["User"]
$password = setupInfo["Password"]

#get today's date for use in later scripts
$today = Time.now.month.to_s + "/" + Time.now.day.to_s + "/" + Time.now.year.to_s
quit
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