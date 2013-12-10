# encoding: utf-8
require 'rubygems'

gem 'test-unit'
require "test/unit"
require 'test/unit/ui/console/testrunner'
require 'httmultiparty'
require "json"
require 'rake'
require 'deathbycaptcha'
require 'setup'
require 'services_definition/question_service'

Dir["resumeupload/*.rb"].each {|file| require file }
Dir["getreferred/*.rb"].each {|file| require file }

require 'yajl'
require 'rake'
require 'ci/reporter/rake/test_unit'
require 'ci/reporter/rake/test_unit_loader'
require 'ap'
require 'uri'

class TestHandler
  include Test::Unit::Assertions
  extend Test::Unit::Assertions

  if $environment == "demo"
    require 'company/demo/create_user'
    include Demo::CreateUser
  else
    Dir[File.join(File.dirname(__FILE__), 'company') + "/#{$selected_company}/*.rb"].each { |file|
      next if file =~ /job_feed/
      require file
      include self.const_get("#{$selected_company}".capitalize).const_get(File.basename(file).gsub('.rb','').split("_").map{|ea| ea.capitalize}.join)
    }
  end

  attr_accessor :browser, :test_data, :answer_json, :driver, :wait, :wait_less, :wait_more, :verification_errors

  def initialize(browser = :firefox)
    # @server = server
    @browser = browser
    @test_data = get_test_data
    @answer_json=Array.new
    setup
  end

  def setup

    if ENV['HEADLESS'].nil? or ENV['HEADLESS'].downcase != "false"
      puts "Launching in headless mode"
      require 'headless'
      headless = Headless.new
      headless.start
    end

    # To solve the rbuff full issue
    # client = Selenium::WebDriver::Remote::Http::Default.new
    # client.timeout = 120 # seconds

    # @driver = Selenium::WebDriver.for(:remote, :url => @sel_grid_url, :desired_capabilities => @browser, :http_client => client)

    ## TO MAKE LOCATION DISABLED ###
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
    file = File.open("test_data.json","r")
    parser = Yajl::Parser.new
    parser.parse(file)
  end

  def wait_for_element_not_present(hash, message)
    begin
      assert_nothing_raised @wait_to_fail.until { @driver.find_element hash }
    rescue
      @driver.save_screenshot("#{message}.png")
      assert_nothing_raised @wait_to_fail.until { @driver.find_element hash }
    end
  end

  def wait_for_text_not_present(text, message)
    begin
      assert_nothing_raised @wait_to_fail.until { @driver.find_element(:tag_name => "body").text.include?(text) }
    rescue
      @driver.save_screenshot("#{message}.png")
      assert_nothing_raised @wait_to_fail.until { @driver.find_element(:tag_name => "body").text.include?(text) }
    end
  end

  def wait_for_element_present(hash, message, wait="wait")
    begin
      self.instance_variable_get("@#{wait}").until{ @driver.find_element hash }
    rescue
      @driver.save_screenshot("#{message}.png")
      assert_match "true","false", "#{message}"
    end
  end

  def wait_for_text_present(text, message, wait="wait")
    begin
      self.instance_variable_get("@#{wait}").until { @driver.find_element(:tag_name => "body").text.include?(text)}
    rescue
      @driver.save_screenshot("#{message}.png")
      assert_match "true","false", "#{message}"
    end
  end

  def basic_elements_present
    assert @driver.find_elements(:xpath,"//img[@alt='Happy people smiling']"), "Company Image link is present"
    assert @driver.execute_script("return document.getElementsByTagName('img')[1].complete"), "Company image loads successfully"
    title = []
    href = []
    get_title_ids(0,title,href)
    assert_operator title.length,:>,0,"Home page displays atleast 1 job"
    assert @driver.find_elements(:xpath,"//img[@alt='JIBE logo']"), "Powered by JIBE is present"
  end

  def get_jobid (number = 1)
    @driver.get "http://#{$env}/"
    if number > 9
      pages = number/10 + 1
      while pages > 0
        @driver.execute_script("javascript:window.onload=toBottom();"+
        "function toBottom(){" +
        "window.scrollTo(0,Math.max(document.documentElement.scrollHeight," +
        "document.body.scrollHeight,document.documentElement.clientHeight));" +
        "}")
        sleep 2
        pages= pages - 1
      end
    end
    e = @driver.find_element(:css, "td[class='job-title'] a").click
    sleep(1)
    href = @driver.current_url
    #        jobs = @driver.find_elements(:class,"job-title")
    #        unless jobs[number].nil? || jobs[number]==0
    #            link = jobs[number].find_element(:tag_name => "a")
    #        else
    #            @driver.save_screenshot("No Jobs.png")
    #            raise "No jobs"
    #        end

    #        href = e.attribute("href")
    #        puts "href before: #{href}"

    newhref= href.split("/").last
    return newhref
  end

  def job_listings_scroll(pages=5)
    #Check if scrolling to bottom auto updates the list with new jobs
    jobs    = @driver.find_element(:class,"jobs")
    titles  = jobs.find_elements(:xpath,"li")
    prev = titles.length
    now = 0
    (0..pages).each do |i|
      wait_for_element_present({:class=>"more-jobs"}, "no more jobs")

      i = 0
      begin
        # @wait.until {  @driver.find_element(:class,"more-jobs") }
        wait_for_element_present({:class=>"more-jobs"}, "no more jobs")
        @driver.execute_script("javascript:window.onload=toBottom();"+
        "function toBottom(){" +
        "window.scrollTo(0,Math.max(document.documentElement.scrollHeight," +
        "document.body.scrollHeight,document.documentElement.clientHeight));" +
        "}")
        # @driver.action.move_to(more_jobs1).perform
        sleep 2
        jobs1    = @driver.find_element(:class,"jobs")
        titles1  = jobs1.find_elements(:xpath,"li")
        now = titles1.length

        assert_operator prev, :<, now, "After scrolling to bottom no new jobs are getting added"
        prev =now
      rescue
        raise
        i = i + 1
        sleep 2

        retry if i < 3
        assert_operator prev, :<, now, "After scrolling to bottom no new jobs are getting added"
      end
    end
  end

  def searching testing_what, text="Product", number=1
    #All aspects related to search
    case testing_what
    when "search_text" then
      search_text(text)
    when "search_numbers" then
      search_numbers(number)
    when "search_garbage" then
      search_garbage()
    when "search_alphanumeric" then
      search_alphanumeric()
    else
      puts "\nNo paramter passed\n"
    end
  end

  def search_text(text="Product")
    #Check if scrolling to bottom auto updates the list with new jobs
    title = []
    href = []
    @driver.find_element(:xpath,"//div[@id='content']/div/div/div[2]/form/input")
    @driver.find_element(:xpath,"//div[@id='content']/div/div/div[2]/form/input").clear
    @driver.find_element(:xpath,"//div[@id='content']/div/div/div[2]/form/input").send_keys "#{text}"
    @driver.find_element(:xpath, "//div[@id='content']/div/div/div[2]/form/input").send_keys [:return]
    get_title_ids(0,title,href)
    #check_all_unique(href)
    assert_operator title.length,:>,0,"Text Search returns atleast 1 result"
  end

  def search_numbers(number=1)
    #Check if scrolling to bottom auto updates the list with new jobs
    title = []
    href = []
    @driver.find_element(:xpath,"//div[@id='content']/div/div/div[2]/form/input")
    @driver.find_element(:xpath,"//div[@id='content']/div/div/div[2]/form/input").clear
    @driver.find_element(:xpath,"//div[@id='content']/div/div/div[2]/form/input").send_keys "#{number}"
    @driver.find_element(:xpath, "//div[@id='content']/div/div/div[2]/form/input").send_keys [:return]
    get_title_ids(0,title,href)
    #check_all_unique(href)
    assert_operator title.length,:>,0,"Number Search returns atleast 1 result"
  end

  def search_garbage
    #Check if scrolling to bottom auto updates the list with new jobs
    title = []
    href = []
    @driver.find_element(:xpath,"//div[@id='content']/div/div/div[2]/form/input")
    @driver.find_element(:xpath,"//div[@id='content']/div/div/div[2]/form/input").clear
    @driver.find_element(:xpath,"//div[@id='content']/div/div/div[2]/form/input").send_keys "hdbjasbjks"
    @driver.find_element(:xpath, "//div[@id='content']/div/div/div[2]/form/input").send_keys [:return]
    #get_title_ids(0,title,href)
    #assert_operator title.length,:==,0,"Garbage Search returns no results"
    begin
      @wait.until { @driver.find_element(:tag_name => "body").text.include?("no jobs were found that match your search") }
    rescue
      @driver.save_screenshot("garbage_gave_result.png")
      assert_match "true","false","A garbage search gave results"
    end
  end

  def search_alphanumeric
    #Check if scrolling to bottom auto updates the list with new jobs
    title = []
    href = []
    @driver.find_element(:xpath,"//div[@id='content']/div/div/div[2]/form/input").clear
    @driver.find_element(:xpath,"//div[@id='content']/div/div/div[2]/form/input").send_keys "Weekend 5th"
    @driver.find_element(:xpath, "//div[@id='content']/div/div/div[2]/form/input").send_keys [:return]
    get_title_ids(0,title,href)
    #check_all_unique(href)
    assert_operator title.length,:>,0,"Text Search returns atleast 1 result"
  end

  def get_title_ids (start_from=0, title=[], href=[])
    #Part of code which can store all links and titles of jobs displayed
    i=0
    begin
      begin
        @wait.until { @driver.find_element(:class,"jobs") }
      rescue
        @driver.save_screenshot("waiting_for_jobs.png")
        assert_match "true","false","Waiting for jobs to be displayed"
      end
      titles  = @driver.find_elements(:xpath,"//ul[@class='jobs']/li")
      (start_from..(titles.length-1)).each do |i|
        unless titles[i].text.to_s.chomp.strip.empty?
          if "#{titles[i].text.to_s.chomp}" =~ /More Jobs/
          else
            title << titles[i].text.chomp
            link = titles[i].find_element(:tag_name => "a")
            href << link.attribute("href")
          end
        end
      end
    rescue
      i =i+1
      puts "Failed #{i} times because of #{$!}"
      retry if i<3
      @driver.save_screenshot("get_title_id.png")
      raise
    end
  end

  def location_check (pages)
    @driver.get "http://#{$env}/"
    (0..pages).each do |i|
      start_from= i*10
      check_location_present(start_from)
      @driver.find_element(:css, "button.js-next-page").click
      sleep 2
    end
  end

  def check_location_present (start_from=0)
    #Check for locations
    jobs    = @driver.find_element(:class,"jobs")
    titles  = jobs.find_elements(:xpath,"//li")
    (start_from..(titles.length-1)).each do |i|
      unless titles[i].text.to_s.chomp.strip.empty?
        if "#{titles[i].text.to_s.chomp}" =~ /More Jobs/
        else
          # begin
          #     @wait.until { titles[i].find_element(:class, "location") }
          # rescue
          #     @driver.save_screenshot("no_jobs_being_displayed_location_check.png")
          #     assert_match "true","false","No location class detected when searching for jobs"
          # end
          location = titles[i].find_element(:class, "location").text
          jagah = location.split(/,/)
          if jagah[0].nil?
            link = titles[i].find_element(:tag_name => "a")
            href= link.attribute("href")
            href.gsub!(/\D/,'')
            @driver.save_screenshot("#{href}_locationmissing.png")
            assert_match "true","false","The job #{link.text} with address #{link.attribute("href")} does not have a location"
          else
            assert_match "true","true","The job #{link} has a location"
          end
        end
      end
    end
  end

  def check_all_unique (href=[])
    h_length=href.length - 1
    href.sort
    i=0
    while (i< h_length)
      if href[i]==href[i+1]
        assert_match "true","false","The same job:\"#{href[i]}\" is displayed twice"
      end
      i=i+1
    end
  end

  ###############   JOB DESC - START ###############

  def jobdesc_displays (text, text1, text2)
    @driver.get "http://#{$env}/"
    @driver.navigate.refresh
    title = []
    href = []
    get_title_ids(0,title,href)
    title.each_with_index do |i, index|
      @wait_less.until {@driver.find_element(:xpath,"//div[@id='content']/div/div/div[2]/form/input")}
      @driver.find_element(:link, "#{i}").click()
      begin
        @wait.until { @driver.find_element(:tag_name => "body").text.include?("#{text}") }
      rescue
        href[index].gsub!(/\D/,'')
        @driver.save_screenshot("#{href[index]}_#{text}_JobDescPage.png")
        assert_match "true","false","The job description for #{i} does not have the text \"#{text}\""
      end

      begin
        @wait.until { @driver.find_element(:tag_name => "body").text.include?("#{text1}") }
      rescue
        href[index].gsub!(/\D/,'')
        @driver.save_screenshot("#{href[index]}_#{text1}_JobDescPage.png")
        assert_match "true","false","The job description for #{i} does not have the text \"#{text1}\""
      end

      begin
        @wait.until { @driver.find_element(:tag_name => "body").text.include?("#{text2}") }
      rescue
        href[index].gsub!(/\D/,'')
        @driver.save_screenshot("#{href[index]}_#{text2}_JobDescPage.png")
        assert_match "true","false","The job description for #{i} does not have the text \"#{text2}\""
      end

      begin
        @wait.until { @driver.find_element(:link, "Mobile Apply" )}
      rescue
        href[index].gsub!(/\D/,'')
        @driver.save_screenshot("#{href[index]}_MobileApply_JobDescPage.png")
        assert_match "true","false","The job description for #{i} does not have the button \"Mobile Apply\""
      end
      @driver.navigate.back
    end
  end

  ###############   DOCUMENT SERVICES - START ###############

  def resume_upload_services(user_id, repeat = 1)
    if $selected_company == "ups"
      url = "http://#{$env}/upload/999?user_id=#{user_id}&session_id=11232"
    else
      @driver.get "http://#{$env}/"
      jobs    = @driver.find_elements(:class,"job")
      link = jobs[0].find_element(:tag_name => "a")
      href = link.attribute("href")
      href.sub!(/http:\/\/#{$env}\/jobs\//, '')
      url = "http://#{$env}/application/#{href}/login"
    end
    @driver.get url
    login_screen_success(href, user_id, $pwd_to_use) unless $selected_company == "ups"
    resume_email(href, user_id, repeat)
    @driver.get url
    login_screen_success(href, user_id, $pwd_to_use) unless $selected_company == "ups"
    resume_linkedin(href, user_id)
    @driver.get url
    login_screen_success(href, user_id, $pwd_to_use) unless $selected_company == "ups"
    resume_google(href, user_id)
    @driver.get url
    login_screen_success(href, user_id, $pwd_to_use) unless $selected_company == "ups"
    resume_dropbox(href, user_id)
    unless $selected_company == "ups"
      @driver.get url
      login_screen_success(href, user_id, $pwd_to_use)
      resume_basic
    end
  end

  def get_referred
    @driver.get "http://#{$env}/"
    jobs    = @driver.find_elements(:class,"job")
    link = jobs[0].find_element(:tag_name => "a")
    href = link.attribute("href")
    href.sub!(/http:\/\/#{$env}\/jobs\//, '')
    url = "http://#{$env}/getreferred/#{href}/profile"

    @driver.get url
    create_gr_profile
    resume_basic 0
    gr_email
    gr_linkedin
    gr_facebook
    gr_twitter

  end

  ###############   LOCATION SEARCH - START ###############

  def change_search_location (location)
    @driver.get "http://#{$env}/"
    @driver.find_element(:xpath,  "//div[@id='content']/div/div/div[2]/div/span").click
    @driver.find_element(:xpath,  "//div[@id='modal']/div/div[2]/input").clear
    @driver.find_element(:xpath,  "//div[@id='modal']/div/div[2]/input").send_keys "#{location}"
    sleep 2
    buttons = @driver.find_element(:class, "found-locations")
    locs  = buttons.find_elements(:xpath, "//button")
    unless locs.length > 3
      @driver.save_screenshot("no_suggestion_for_location.png")
      assert_operator locs.length,:>,3,"Location search does not return any suggestions for location \"#{location}\""
    end
    (2..(locs.length-1)).each do |i|
      loc_result = locs[i].text.to_s.chomp.strip
      #The X below is actually a special character x (the close button)
      if loc_result =~ /More Jobs|x|Search all locations/
      else
        if (loc_result).include?(location)
          assert_match "true","true", "The search is relevant"
        else
          assert_match "true","false", "The search is NOT relevant, the input is \"#{location}\" and the output is \"#{loc_result}\""
        end
      end
    end
    locs[2].click()
    location=locs[2].text
    begin
      @wait.until { @driver.find_element(:tag_name => "body").text.include?("#{location}")}
    rescue
      @driver.save_screenshot("searched_location_is_not_saved.png")
      assert_match "true","false","The location searched from All Locations cannot be selected to filter results"
    end
    # @driver.navigate.refresh
    # document.getElementsByClassName('icon-globe')[0].click()

    # @driver.execute_script("document.getElementsByClassName('icon-globe')[0].click()")

    # sleep

    @driver.find_element(:class,  "icon-globe").click()
    # begin
    #     @wait.until { @driver.find_element(:xpath,  "//div[@id='content']/div/div/div[2]/div/span")}
    # rescue
    #     @driver.save_screenshot("location_name_display.png")
    #     assert_match "true","false","The new location name is not displayed"
    # end
    # @driver.find_element(:xpath,  "//div[@id='content']/div/div/div[2]/div/span").click()
    # buttons = @driver.find_element(:class, "found-locations")
    # locs  = buttons.find_elements(:xpath, "//button")
    # locs[locs.length-1].click()
    # begin
    #     @wait.until { @driver.find_element(:tag_name => "body").text.include?("All locations")}
    # rescue
    #     @driver.save_screenshot("setting_back_to_all_locations.png")
    #     assert_match "true","false","The location search is not reset back to All locations"
    # end
  end

  ###############   LOGIN SCREEN - START ###############

  def login_screen_checks (user, pass)
    @driver.get "http://#{$env}/"
    jobs = @driver.find_elements(:class,"job")
    link = jobs[0].find_element(:tag_name => "a")
    href = link.attribute("href")
    href.sub!(/http:\/\/#{$env}\/jobs\//, '')
    # p "login screen failure"
    login_screen_failure(href,'somegarbage', pass)
    # p "register screen failure"
    register_screen_failure(href, user, pass)
    # p "forgot password"
    forgot_password_screen(href, user)
    # p "login screen succes"
    login_screen_success(href, user, pass)
  end

  def login_screen_success (job_id, user, pass)
    i =0
    begin
      @driver.get "http://#{$env}/login?jobId=#{job_id}"

      iframe_id = "mirrorFrame"
      login_button = "event-submit"
      login = "submit"
      wait_for_element_present({:id=>"#{iframe_id}"}, "iframedidnotload-#{i}")
      @driver.switch_to.frame iframe_id

      @driver.find_element(:id, login_button).click
      @driver.switch_to.default_content
      @driver.switch_to.frame iframe_id

      sleep(1) # change to wait_for_element

      @driver.find_element(:css, "input[id='username']").clear
      @driver.find_element(:css, "input[id='username']").send_keys user

      sleep(1)

      @driver.find_element(:css, "input[id='password']").clear
      @driver.find_element(:css, "input[id='password']").send_keys pass

      sleep(1)
      @driver.find_element(:css, "button[name='submit']").click
      @driver.switch_to.default_content
      if $selected_company == "activision"
        if @driver.find_element(:css, "span[class='ng-binding']").text.include?("Logged in as")
#          wait_for_text_present("We've got plenty of jobs", "didnot return with the apply success", "wait")
#        if wait_for_text_present("We've got plenty of jobs", "didnot return with the apply success", "wait")
#          @driver.find_element(:css, "span[class='pull-right logged-in-msg ng-binding']").text.include?("Logged in as")
#          return true
#        elsif @driver.find_element(:css, "span[class='ng-binding']").text.include?("Logged in as")
#          return true
#        elsif wait_for_text_present("We've got plenty of jobs", "didnot return with the apply success", "wait")
##          ("Upload a Resume using one of the following:", "didnot return with the apply success", "wait")
#          return true
#        elsif @driver.find_element(:css, "span[class='pull-right logged-in-msg ng-binding']").text.include?("Thank you for exploring career opportunities with Activision!")
#          # this is if the job was not applied for before.
#
#          return true
        end
      end
    rescue
      puts "Failed with error #{$!}"
    end
  end

  def json_response_check(response)
    assert response.has_key?("id"),"The profile question json does not have a key \"id\" for id:#{response["id"]}"
    assert response.has_key?("questions"),"The profile question json does not have a key \"questions\"for id:#{response["id"]}"
    assert response.has_key?("answers"),"The profile question json does not have a key \"answers\"for id:#{response["id"]}"
    assert response.has_key?("repeated"),"The profile question json does not have a key \"repeated\"for id:#{response["id"]}"
    assert response.has_key?("optional"),"The profile question json does not have a key \"optional\"for id:#{response["id"]}"
    assert response.has_key?("ats_id"),"The profile question json does not have a key \"ats_id\"for id:#{response["id"]}"
    assert response.has_key?("question_version"),"The profile question json does not have a key \"question_version\"for id:#{response["id"]}"
    assert response.has_key?("created_at"),"The profile question json does not have a key \"created_at\"for id:#{response["id"]}"
    assert response.has_key?("updated_at"),"The profile question json does not have a key \"updated_at\"for id:#{response["id"]}"
    assert response.has_key?("display_order"),"The profile question json does not have a key \"display_order\"for id:#{response["id"]}"
    if response["questions"].length > 0 && response["answers"].length > 0
      assert_match "true","false", "The Profile Question JSON has strange data for id:#{response["id"]}"
    elsif response["questions"].length == 0 && response["answers"].length == 0
      assert_match "true","false", "The Profile Question JSON has strange data for id:#{response["id"]}"
    elsif response["questions"].length > 0
      response["questions"].each do |i|
        json_response_check(i)
      end
    else
    end
  end

  def frontend_job_apply(job_id, username, password, resume = "basic")

    login_screen_success(job_id, username, password)

    if resume == "basic"
      resume_basic
    elsif resume == "linkedin"
      resume_linkedin(1, username, "jibeqa7@gmail.com")
      @driver.find_element(:link, "Continue").click
    elsif resume == "dropbox"
      resume_dropbox(1, username)
      @driver.find_element(:link, "Next").click
    elsif resume == "google"
      resume_google(1, username)
      @driver.find_element(:link, "Next").click
    end

    i = 10
    application_state = "PROFILE"
    while (application_state =~ /PROFILE|EMPLOYER|JOB|PREQUAL/)
      if i == 10
        application_state = sel_check_state_and_submit(job_id, username, "true")
        i = i +10
      else
        application_state = sel_check_state_and_submit(job_id, username)
      end
    end
    # puts @driver.page_source
    if application_state =~ /COMPLETED/
      # puts  "\n\n\n\nSuccessfully reached the completion with state:#{application_state} for job:#{job_id}\n\n\n\n"
    elsif application_state =~ /knockout/
      # puts "been knocked out successfully with state #{application_state}"
    elsif application_state =~ /nonexistent/
      # puts "The job does not exist the state is #{application_state}"
    else
      # puts "unrecognized state taht being \"#{application_state}\""
    end

    begin
      @wait_more.until { @driver.find_element(:tag_name => "body").text.include?("Complete") || @driver.find_element(:tag_name => "body").text.include?("touch with you shortly") || @driver.find_element(:tag_name => "body").text.include?("Thanks for your application")}
      # puts  "Successfully validated presence of the next question or completion state\n"
    rescue
      @driver.save_screenshot("success_page_after_state_complete.png")
      assert_match "true","false","The success page is not displayed even after job application state is complete"
    end
    # puts @driver.page_source
    # ap @answer_json
    # puts @answer_json

    if $environment == "stg1"
      last_lines_of_log_file = `ssh -t apatil@mobileapplybot1.testbacon.com tail -n 1500 /u/apps/#{$selected_company}-apply-bot/current/log/#{$selected_company}.applybot.staging.log`
      last_few_apps = last_lines_of_log_file.scan(/\*\*\* got(.*)/)
      i_need = last_few_apps.last.last
      i_need.chomp!
      i_need = i_need.gsub(/^(.*?)\[/,'[')
      i_need = i_need.gsub(/[\)]$/,'')
      convert_to_hash = JSON.parse(i_need)
      last_submitted_app = JSON.parse(convert_to_hash[0])
      @answer_json.each do |each_answer|
        if b = last_submitted_app["answers"].detect {|a| a["question_id"] == each_answer["QuestionId"] }
          assert_match b["answer"] , each_answer["Answer"], "The user's answer:#{each_answer["Answer"]} did not match #{b["answer"]}"
          assert_match b["answer_id"] , each_answer["AnswerId"], "The user's answerid:#{each_answer["AnswerId"]} did not match #{b["answer_id"]}"
        else
          assert_match "true","false", "No answer for questionid:#{each_answer["QuestionId"]} is seen in Answer json submitted to Redis queue"
        end
      end
      last_submitted_app["answers"].each do |each_answer|
        if b = @answer_json.detect {|a| a["QuestionId"] == each_answer["question_id"] }
        else
          assert_match "true","false", "Additional questionid :#{each_answer["question_id"]} is seen in the answer json which is not written by the user "
        end
      end
    end

  end

  def sel_create_answers(questions)
    answer = Array.new

    if questions["questions"].length > 0 && questions["answers"].length == 0
      repeatable = questions["repeated"]
      min_repeats=1
      if repeatable
        min_repeats = questions["min_repeats"] if questions.has_key?("min_repeats")
        max_repeats = questions["max_repeats"] if questions.has_key?("max_repeats")
      end
      # puts "this question is repeatable with value #{repeatable}\n\n"
      # puts "\n\n\n\n\n\nthis min_repeats is #{min_repeats}\n\n"
      # puts "this max_repeats is #{max_repeats}\n\n"
      (1..min_repeats).each do |min_repeat|
        questions["questions"].each do |question|
          sel_single_answer(question, repeatable, min_repeat, max_repeats)
        end
      end
    else
      repeatable = questions["repeated"]
      min_repeats=1
      if repeatable
        min_repeats = questions["min_repeats"] if questions.has_key?("min_repeats")
        max_repeats = questions["max_repeats"] if questions.has_key?("max_repeats")
      end
      # puts "this question is repeatable with value #{repeatable}\n\n"
      # puts "this min_repeats is #{min_repeats}\n\n"
      # puts "this max_repeats is #{max_repeats}\n\n"

      sel_single_answer(questions, repeatable, min_repeats, max_repeats)
    end
  end

  # def random_text (no_of_characters)
  #     characters = ('a'..'z').to_a + ('A'..'Z').to_a
  #     # Prior to 1.9, use .sample, not .sample
  #     (0..no_of_characters).map{characters.sample}.join
  # end

  def random_text(length)
    # puts "the lenght is #{length}\n"
    string = ""
    chars = ("A".."Z").to_a + ('a'..'z').to_a
    (1..length).each do
      string << chars[rand(chars.length-1)]
    end
    string
  end

  def random_numbers(length)
    # puts "the lenght is #{length}\n"
    string = ""
    chars = ("0".."9").to_a
    (1..length).each do
      string << chars[rand(chars.length-1)]
    end
    string
  end

  def sel_single_answer(questions, repeatable, min_repeats, max_repeats)
    if questions["answer_type"] =~ /text_short/
      if questions.has_key?("validations")
        n=3
        minimum_characters = 0
        maximum_characters = 0
        if questions["validations"].length > 1 || questions["validations"].find { |e| /^REQUIRED_IF/ =~ e }
          questions["validations"].each do |i|
            # puts "outside loop the inex is #{i}\n"
            if (i =~ /MAXLENGTH\((.*?)\)/)
              # i = i.gsub!(/MAXLENGTH\(/,"")
              # n = i.gsub!(/\)/,"").to_i
              # n=5 if n>=5
              # maximum_characters = i.gsub!(/\)/,"").to_i
              maximum_characters = $1.to_i
            elsif (i =~ /MINLENGTH\((.*?)\)/)
              # i = i.gsub!(/MINLENGTH\(/,"")
              # n = i.gsub!(/\)/,"").to_i
              # minimum_characters == i.gsub!(/\)/,"").to_i
              minimum_characters = $1.to_i
            end
          end
          if minimum_characters != 0
            n = minimum_characters
          elsif minimum_characters == 0 && maximum_characters < 5
            n = 3
          elsif minimum_characters == 0 && maximum_characters >= 5
            n = 5
          end
          # puts "the number of characters is #{n}"
          # puts "the Min number of characters is #{minimum_characters}"
          # puts "the Max number of characters is #{maximum_characters}\n\n\n\n"

          if questions["validations"].index "EMAIL"
            #answer = CreateAnswers.text_answer(@test_data["email"][rand(4)], questions["id"], questions["answers"][0]["id"], repeat)
            name = "question_"+"#{questions["id"]}"+"-#{min_repeats}"
            #puts "the name is #{name}\n"
            @driver.find_element(:name, name).clear
            # email_text = random_text(n)
            # enter_email ="#{email_text}" +"@#{email_text}.com"
            data_to_type = @test_data["email"].sample
            @driver.find_element(:name, name).send_keys data_to_type
            # @driver.find_element(:name, name).send_keys "#{enter_email}"

          elsif questions["validations"].index "ZIPCODE"
            # answer = CreateAnswers.text_answer(@test_data["zipcode"][rand(4)], questions["id"], questions["answers"][0]["id"], repeat)
            name = "question_"+"#{questions["id"]}"+"-#{min_repeats}"
            #puts "the name is #{name}\n"
            @driver.find_element(:name, name).clear
            data_to_type = @test_data["zipcode"].sample
            @driver.find_element(:name, name).send_keys data_to_type

          elsif questions["validations"].index "PHONE"
            # answer = CreateAnswers.text_answer(@test_data["phone"][rand(4)], questions["id"], questions["answers"][0]["id"], repeat)
            name = "question_"+"#{questions["id"]}"+"-#{min_repeats}"
            #puts "the name is #{name}\n"
            @driver.find_element(:name, name).clear
            data_to_type = @test_data["phone"].sample
            @driver.find_element(:name, name).send_keys data_to_type

          elsif questions["validations"].index "MAXLENGTH(2)"
            # answer = CreateAnswers.text_answer(@test_data["state"][rand(4)], questions["id"], questions["answers"][0]["id"], repeat)
            name = "question_"+"#{questions["id"]}"+"-#{min_repeats}"
            #puts "the name is #{name}\n"
            @driver.find_element(:name, name).clear
            data_to_type = @test_data["state"].sample
            @driver.find_element(:name, name).send_keys data_to_type

          elsif questions["validations"].index "SSN"
            #answer = CreateAnswers.text_answer(@test_data["ssn"][rand(4)], questions["id"], questions["answers"][0]["id"], repeat)
            name = "question_"+"#{questions["id"]}"+"-#{min_repeats}"
            #puts "the name is #{name}\n"
            @driver.find_element(:name, name).clear
            data_to_type = @test_data["ssn"].sample
            @driver.find_element(:name, name).send_keys data_to_type

          elsif ((questions["validations"].index "PATTERN(^(https://|http://).+)") || (questions["validations"].index "PATTERN(https?:\\/\\/.+\\..+)"))
            #answer = CreateAnswers.text_answer(@test_data["ssn"][rand(4)], questions["id"], questions["answers"][0]["id"], repeat)
            name = "question_"+"#{questions["id"]}"+"-#{min_repeats}"
            #puts "the name is #{name}\n"
            @driver.find_element(:name, name).clear
            data_to_type = "http://something.com"
            @driver.find_element(:name, name).send_keys data_to_type

          elsif questions["validations"].index "PATTERN([0-9]{4})"
            #answer = CreateAnswers.text_answer(@test_data["ssn"][rand(4)], questions["id"], questions["answers"][0]["id"], repeat)
            name = "question_"+"#{questions["id"]}"+"-#{min_repeats}"
            #puts "the name is #{name}\n"
            @driver.find_element(:name, name).clear
            data_to_type = "2012"
            @driver.find_element(:name, name).send_keys data_to_type

          elsif questions["validations"].index "NUMERIC"
            name = "question_"+"#{questions["id"]}"+"-#{min_repeats}"
            #puts "the name is #{name}\n"
            @driver.find_element(:name, name).clear
            if questions["value"] =~ /year/i
              data_to_type = "2012"
              @driver.find_element(:name, name).send_keys data_to_type#@test_data["text"].sample
            else
              data_to_type = random_numbers(n)
              @driver.find_element(:name, name).send_keys data_to_type#@test_data["text"].sample
            end

          elsif questions["validations"].index "PATTERN(^[a-zA-Z- ']+$)"
            #answer = CreateAnswers.text_answer(@test_data["ssn"][rand(4)], questions["id"], questions["answers"][0]["id"], repeat)
            name = "question_"+"#{questions["id"]}"+"-#{min_repeats}"
            #puts "the name is #{name}\n"
            @driver.find_element(:name, name).clear
            data_to_type = random_text(n)
            @driver.find_element(:name, name).send_keys data_to_type#@test_data["text"].sample

          elsif ((questions["validations"].index 'PATTERN(^(0[1-9]|1[012])[-/](0[1-9]|[12][0-9]|3[01])[-/](19|20)\d\d$)') || (questions["validations"].index 'PATTERN(^(0[1-9]|1[012])/((0[1-9]|[12][0-9]|3[01])/(19|20)\d\d$))'))
            #answer = CreateAnswers.text_answer(@test_data["ssn"][rand(4)], questions["id"], questions["answers"][0]["id"], repeat)
            name = "question_"+"#{questions["id"]}"+"-#{min_repeats}"
            #puts "the name is #{name}\n"
            @driver.find_element(:name, name).clear
            data_to_type = random_text(n)
            @driver.find_element(:name, name).send_keys "12/12/2012"

          elsif questions["validations"].index 'PATTERN((^(0[1-9])|(1[0-2]))[-/]((1900)|(20[0-9][0-9]))$)'
            #answer = CreateAnswers.text_answer(@test_data["ssn"][rand(4)], questions["id"], questions["answers"][0]["id"], repeat)
            name = "question_"+"#{questions["id"]}"+"-#{min_repeats}"
            #puts "the name is #{name}\n"
            @driver.find_element(:name, name).clear
            data_to_type = random_text(n)
            @driver.find_element(:name, name).send_keys "12/2012"

          else
            name = "question_"+"#{questions["id"]}"+"-#{min_repeats}"
            #puts "the name is #{name}\n"
            @driver.find_element(:name, name).clear
            data_to_type = random_text(n)
            @driver.find_element(:name, name).send_keys data_to_type#questions["value"]

          end

        elsif questions["validations"].index "REQUIRED"
          # answer = CreateAnswers.text_answer("#{questions["value"]}", questions["id"], questions["answers"][0]["id"], repeat)
          name = "question_"+"#{questions["id"]}"+"-#{min_repeats}"
          # puts "the name is #{name}\n"
          @driver.find_element(:name, name).clear
          data_to_type = random_text(n)
          @driver.find_element(:name, name).send_keys data_to_type #questions["value"]
        else
          #  name = "question_"+"#{questions["id"]}"+"-#{min_repeats}"
          # # puts "the name is #{name}\n"
          #  @driver.find_element(:name, name).clear
          #  @driver.find_element(:name, name).send_keys random_text(n)#questions["value"]
        end
      else
        # answer = CreateAnswers.skip_answer(questions["id"], questions["answers"][0]["id"], repeat)
        # puts "skipped this answer #{questions["id"]} \n"
      end

      # puts "Answer:#{data_to_type}\tQuestionId=#{questions["ats_id"]}\tAnswerId=#{questions["answers"][0]["ats_id"]}" unless data_to_type.nil?

      @answer_json << {
        "Answer" => data_to_type,
        "QuestionId" => questions["ats_id"],
        "AnswerId" => questions["answers"][0]["ats_id"]
      } unless data_to_type.nil?

    elsif questions["answer_type"] =~ /select_single/
      begin
        unless questions.has_key?("validations") #questions["validations"].index "REQUIRED"
          return "Ignore this question"
        end
      rescue
      end
      number_of_possible_answers = questions["answers"].length

      name = "question_"+"#{questions["id"]}"+"-#{min_repeats}"
      #puts "the number of possible anseer si #{number_of_possible_answers}\n\n"
      if number_of_possible_answers > 5
        i = number_of_possible_answers -1
        # answer_ats_id = 0 ### Need to check this if we need in terms of scope
        while (i >=0)
          choice = questions["answers"][i]["value"]
          answer_ats_id = questions["answers"][i]["ats_id"]
          break if questions["answers"][i]["next_state"] =~ /incomplete/
          i = i-1
        end
        #answer = CreateAnswers.select_answer(questions["id"], choice, repeat)
        # puts "the name is #{name}\n"
        # puts " the choice is #{choice}"
        data_to_select = choice
        Selenium::WebDriver::Support::Select.new(@driver.find_element(:name, name)).select_by(:text, data_to_select)

        # puts "Answer:#{data_to_select}\tQuestionId=#{questions["ats_id"]}\tAnswerId:#{answer_ats_id}" unless data_to_select.nil?

        @answer_json << {
          "Answer" => data_to_select,
          "QuestionId" => questions["ats_id"],
          "AnswerId" => answer_ats_id
        } unless data_to_select.nil?

      elsif questions.has_key? "list_identifier"

        all_options =  @driver.find_element(:name, name).find_elements(:tag_name, 'option')
        data_to_select = all_options.last.text
        Selenium::WebDriver::Support::Select.new(@driver.find_element(:name, name)).select_by(:text, data_to_select)
=begin
                puts "printing done"
                if questions["list_identifier"] == "country_list" || questions["list_identifier"] == "countries" || questions["list_identifier"] == "country_issued_list"
                        #puts "In the country list \n"
                        if $selected_company == "abrazo"
                            data_to_select = "US-United States"
                            Selenium::WebDriver::Support::Select.new(@driver.find_element(:name, name)).select_by(:text, data_to_select)
                        elsif $selected_company =~ /wcrx|usaa/
                            data_to_select = "U.S."
                            Selenium::WebDriver::Support::Select.new(@driver.find_element(:name, name)).select_by(:text, data_to_select)
                        else
                            data_to_select = "United States"
                            Selenium::WebDriver::Support::Select.new(@driver.find_element(:name, name)).select_by(:text, data_to_select)
                        end
                elsif questions["list_identifier"] == "state_profile_list"
                    #puts "In the State list \n"
                    data_to_select = "Maine"
                    Selenium::WebDriver::Support::Select.new(@driver.find_element(:name, name)).select_by(:text, data_to_select)
                elsif questions["list_identifier"] == "state_list"
                    #puts "In the State list \n"
                    if $selected_company =~ /wcrx|usaa/
                        data_to_select = "Florida"
                        Selenium::WebDriver::Support::Select.new(@driver.find_element(:name, name)).select_by(:text, data_to_select)
                    else
                        data_to_select = "CO"
                        Selenium::WebDriver::Support::Select.new(@driver.find_element(:name, name)).select_by(:text, data_to_select)
                    end
                elsif questions["list_identifier"] =~ /employer_month_list|start_month_list/
                    #puts "In the State list \n"
                    data_to_select = "Jan"
                    Selenium::WebDriver::Support::Select.new(@driver.find_element(:name, name)).select_by(:text, data_to_select)
                elsif questions["list_identifier"] =~ /employer_day_list|day_31_list/
                    #puts "In the State list \n"
                    data_to_select = "03"
                    Selenium::WebDriver::Support::Select.new(@driver.find_element(:name, name)).select_by(:text, data_to_select)
                elsif questions["list_identifier"] == "start_year_list"
                    #puts "In the State list \n"
                    data_to_select = "2013"
                    Selenium::WebDriver::Support::Select.new(@driver.find_element(:name, name)).select_by(:text, data_to_select)
                elsif questions["list_identifier"] =~ /year_list/
                    #puts "In the State list \n"
                    data_to_select = "2012"
                    Selenium::WebDriver::Support::Select.new(@driver.find_element(:name, name)).select_by(:text, data_to_select)
                elsif questions["list_identifier"] == "years"
                    #puts "In the State list \n"
                    data_to_select = "2012"
                    Selenium::WebDriver::Support::Select.new(@driver.find_element(:name, name)).select_by(:text, data_to_select)
                elsif questions["list_identifier"] == "months"
                    #puts "In the State list \n"
                    data_to_select = "3"
                    Selenium::WebDriver::Support::Select.new(@driver.find_element(:name, name)).select_by(:text, data_to_select)
                elsif questions["list_identifier"] == "days"
                    #puts "In the State list \n"
                    data_to_select = "3"
                    Selenium::WebDriver::Support::Select.new(@driver.find_element(:name, name)).select_by(:text, data_to_select)
                elsif questions["list_identifier"] == "states"
                    #puts "In the State list \n"
                    if $selected_company =~ /usaa/
                        data_to_select = "Florida"
                        Selenium::WebDriver::Support::Select.new(@driver.find_element(:name, name)).select_by(:text, data_to_select)
                    else
                        data_to_select = "CO"
                        Selenium::WebDriver::Support::Select.new(@driver.find_element(:name, name)).select_by(:text, data_to_select)
                    end
                elsif questions["list_identifier"] == "certificate_list"
                    #puts "In the State list \n"
                    data_to_select = "Diploma"
                    Selenium::WebDriver::Support::Select.new(@driver.find_element(:name, name)).select_by(:text, data_to_select)
                elsif questions["list_identifier"] == "compensation_list"
                    #puts "In the State list \n"
                    data_to_select = "Open"
                    Selenium::WebDriver::Support::Select.new(@driver.find_element(:name, name)).select_by(:text, data_to_select)
                elsif questions["list_identifier"] == "source_type"
                    #puts "In the State list \n"
                    if $selected_company == "gm"
                        data_to_select = "Other"
                        Selenium::WebDriver::Support::Select.new(@driver.find_element(:name, name)).select_by(:text, data_to_select)
                    else
                        data_to_select = "Billboard"
                        Selenium::WebDriver::Support::Select.new(@driver.find_element(:name, name)).select_by(:text, data_to_select)
                    end
                elsif questions["list_identifier"] == "billboard"
                    #puts "In the State list \n"
                    if $selected_company == "gm"
                        data_to_select = "Other"
                        Selenium::WebDriver::Support::Select.new(@driver.find_element(:name, name)).select_by(:text, data_to_select)
                    else
                        data_to_select = "Billboard"
                        Selenium::WebDriver::Support::Select.new(@driver.find_element(:name, name)).select_by(:text, data_to_select)
                    end
                elsif questions["list_identifier"] == "unitedstates"
                    #puts "In the State list \n"
                    data_to_select = "Alabama"
                    Selenium::WebDriver::Support::Select.new(@driver.find_element(:name, name)).select_by(:text, data_to_select)
                elsif questions["list_identifier"] == "unitedstates_alabama"
                    #puts "In the State list \n"
                    data_to_select = "Albertville"
                    Selenium::WebDriver::Support::Select.new(@driver.find_element(:name, name)).select_by(:text, data_to_select)
                elsif questions["list_identifier"] == "US_state_list"
                    #puts "In the State list \n"
                    data_to_select = "Alabama"
                    Selenium::WebDriver::Support::Select.new(@driver.find_element(:name, name)).select_by(:text, data_to_select)
                elsif questions["list_identifier"] == "years_license"
                    #puts "In the State list \n"
                    data_to_select = "2012"
                    Selenium::WebDriver::Support::Select.new(@driver.find_element(:name, name)).select_by(:text, data_to_select)

                elsif questions["list_identifier"] =~ /source|source_type_University-Recruiting/
                    #puts "In the State list \n"

                    if $selected_company == "hcawestflorida"
                        data_to_select = "Other"
                        Selenium::WebDriver::Support::Select.new(@driver.find_element(:name, name)).select_by(:text, data_to_select)
                    else
                        data_to_select = "University Recruiting"
                        Selenium::WebDriver::Support::Select.new(@driver.find_element(:name, name)).select_by(:text, data_to_select)
                    end

                elsif questions["list_identifier"] =~ /source_type_Other/
                    data_to_select = "Job Line"
                    Selenium::WebDriver::Support::Select.new(@driver.find_element(:name, name)).select_by(:text, data_to_select)

                else
                    puts "No recognized list_identifier that being #{questions["list_identifier"]}"
                    list = @driver.execute_script("return document.getElementsByName('#{name}')[0].textContent")
                    puts " \n\nthe list is  #{list.inspect}\n\n"
                end
=end
        # puts "Answer:#{data_to_select}\tQuestionId=#{questions["ats_id"]}\tAnswerId:#{questions["answers"][0]["ats_id"]}" unless data_to_select.nil?
        # puts "Name:#{name}\tValue:#{questions["value"]}\t\tAnswer:#{data_to_select}" unless data_to_select.nil?

        @answer_json << {
          "Answer" => data_to_select,
          "QuestionId" => questions["ats_id"],
          "AnswerId" => questions["answers"][0]["ats_id"]
        } unless data_to_select.nil?

      elsif number_of_possible_answers >= 1
        #puts "Im in the less than 5 elements as options section\n"
        i = number_of_possible_answers -1
        j=0

        while (j <= i)
          choice = questions["answers"][j]["id"]
          data_to_select = questions["answers"][j]["value"]
          break unless questions["answers"][j]["next_state"] =~ /knockout/
          j = j+1
        end
        #answer = CreateAnswers.select_answer(questions["id"], choice, repeat)
        #puts "the name is #{name}\n"
        #puts " the choice is #{choice}"
        if min_repeats > 1
          @driver.find_element(:css, "div.question-fields[data-index=\"#{min_repeats}\"] button.input-facade[value=\"#{choice}\"]").click
        else
          @driver.find_element(:css, "button.input-facade[value=\"#{choice}\"]").click
        end

        # puts "Answer:#{data_to_select}\tQuestionId=#{questions["ats_id"]}\tAnswerId:#{questions["answers"][j]["ats_id"]}" unless  choice.nil?
        # puts "Name:#{name}\tValue:#{questions["value"]}\t\tAnswer:#{choice}" unless  choice.nil?

        # puts "#{questions["value"]}"
        @answer_json << {
          "Answer" => data_to_select,
          "QuestionId" => questions["ats_id"],
          "AnswerId" => questions["answers"][j]["ats_id"]
        } unless choice.nil?

        return "nonext"
      else
        puts "This question:#{questions.inspect} is a single_select but does not have the key list_identifier nor does it have options"
      end

    elsif questions["answer_type"] =~ /select_multi/
      # unless questions.has_key?("validations")
      #     return "Ignore this question"
      # end
      # begin
      #     unless questions.has_key?("validations") #questions["validations"].index "REQUIRED"
      #         return "Ignore this question"
      #     end
      # rescue
      # end
      name = "question_"+"#{questions["id"]}"+"-#{min_repeats}"
      #puts "the name is #{name}\n"
      number_of_possible_answers = questions["answers"].length
      answer_position=0
      if number_of_possible_answers > 5

        i = number_of_possible_answers -1
        # answer_ats_id = 0 ### Need to check this if we need in terms of scope
        while (i >=0)
          choice = questions["answers"][i]["value"]
          answer_ats_id = questions["answers"][i]["ats_id"]
          break if questions["answers"][i]["next_state"] =~ /incomplete/
          i = i-1
        end
        #answer = CreateAnswers.select_answer(questions["id"], choice, repeat)
        # puts "the name is #{name}\n"
        # puts " the choice is #{choice}"
        data_to_select = choice
        Selenium::WebDriver::Support::Select.new(@driver.find_element(:name, name)).select_by(:text, data_to_select)

        # puts "Answer:#{data_to_select}\tQuestionId=#{questions["ats_id"]}\tAnswerId:#{answer_ats_id}" unless data_to_select.nil?

        @answer_json << {
          "Answer" => data_to_select,
          "QuestionId" => questions["ats_id"],
          "AnswerId" => answer_ats_id
        } unless data_to_select.nil?

      else
        (questions["answers"]).each_with_index do |i, location|
          choice = i["id"]
          answer_position=location
          @driver.find_element(:css, "button.input-facade[value=\"#{choice}\"]").click
          break #Delete this if answersll answers need to be selected.
        end

        # puts "Answer:#{choice}\tQuestionId=#{questions["ats_id"]}\tAnswerId:#{questions["answers"][answer_position]["ats_id"]}" unless  choice.nil?
        # puts "Name:#{name}\tValue:#{questions["value"]}\t\tAnswer:#{choice}"

        @answer_json << {
          "Answer" => questions["answers"][answer_position]["value"],
          "QuestionId" => questions["ats_id"],
          "AnswerId" => questions["answers"][answer_position]["ats_id"]
        }  unless choice.nil?
      end

    elsif questions["answer_type"] =~ /text_long/
      #answer = CreateAnswers.text_answer("#{questions["value"]}", questions["id"], questions["answers"][0]["id"], repeat)
      name = "question_"+"#{questions["id"]}"+"-#{min_repeats}"
      #puts "the name is #{name}\n"
      @driver.find_element(:name, name).clear
      # data_to_type =  questions["value"]
      data_to_type = random_text(5)
      @driver.find_element(:name, name).send_keys data_to_type
      # puts "Name:#{name}\tValue:#{questions["value"]}\t\tAnswer:#{data_to_type}"
      # puts "Answer:#{data_to_type}\tQuestionId=#{questions["ats_id"]}\tAnswerId=#{questions["answers"][0]["ats_id"]}" unless data_to_type.nil?

      @answer_json << {
        "Answer" => data_to_type,
        "QuestionId" => questions["ats_id"],
        "AnswerId" => questions["answers"][0]["ats_id"]
      } unless data_to_type.nil?

    else
      puts "the unaccounted  answer type is #{questions["answer_type"]}"
    end
  end

  def sel_check_state_and_submit(job_id, username, first_time = "false")
    if first_time == "false"
      response = CheckState.job_by_user(job_id, username)
    else
      response = CheckState.job_by_user(job_id, username, "true")
    end
    # puts "Checking for next state\n"
    # ap response.parsed_response #if response.parsed_response["application_state"] == "JOB"
    # puts @driver.current_url
    #########################################################################################

    # to avoid race condition
    i=1

    while response.parsed_response.has_key? ("stacktrace") && i < 4 do
      puts "\n\n\n\n\n\n\n\n\nit failed #{i} times\n\n\n\n\n\n\n\n\n"
      response = CheckState.job_by_user(job_id, username)
      sleep 2
      i += 1
    end
    ##########################################################################################
    if response.parsed_response.has_key? "stacktrace"
      ap response.parsed_response
      assert_match "true", "false", "Job State does not return a known error neither does it provide next question"
      return "nonexistent"
    else
      print "Worked after #{i} attempt(s)" if i > 1
      assert response.parsed_response.has_key?("application_state"),"No key \"application_state\" is returned"
      state = response.parsed_response["application_state"]
      unless state =~ /COMPLETED/i
        progress_bar = @driver.find_element(:xpath, "//div[contains(@class,\"label-progress\")]").text
        prev_progress_bar = progress_bar.gsub!(/\D/,'').to_i
        # puts "Progress bar after sub is #{prev_progress_bar}"
        current_url= @driver.current_url

        questions = response.parsed_response["question_state"]["question"]

        begin
          @wait_much_more.until { @driver.find_element(:tag_name => "body").text.include?("Complete") || @driver.find_element(:tag_name => "body").text.include?("touch with you shortly")}
          # puts  "Successfully validated presence of the next question or completion state\n"
        rescue
          @driver.save_screenshot("questions_page_failed_to_open.png")
          assert_match "true","false","Question page failed to be displayed"
        end

        answer_i =0
        begin
          answer = sel_create_answers(questions)
        rescue Selenium::WebDriver::Error::NoSuchElementError
          puts "The error message while trying to answer a question is #{$!}"
          puts "\n\n Trying again"
          answer_i = answer_i +1
          sleep 2
          @driver.save_screenshot("NoSuchElementError_#{answer_i}_attempt.png")
          retry if answer_i < 3
          raise
        rescue
          puts "The NEW error message while trying to answer a question is #{$!}"
        end

        # ap response.parsed_response
        # # assert_match  response.parsed_response["state"],"complete","The answer "

        @driver.find_element(:xpath, "//button[@type='submit']").click unless answer =~ /nonext/
        # sleep 2

        next_url= @driver.current_url
        sleeping=0
        while (next_url == current_url && sleeping < 30)
          next_url= @driver.current_url
          sleep 1
          sleeping =sleeping+1

        end

        begin
          @wait_more.until { @driver.find_element(:tag_name => "body").text.include?("Complete") || @driver.find_element(:tag_name => "body").text.include?("touch with you shortly") || @driver.find_element(:tag_name => "body").text.include?("Thanks for your application")}
          # puts  "Successfully validated presence of the next question or completion state\n"
        rescue
          @driver.save_screenshot("next_question_does_not_load.png")
          assert_match "true","false","The next question after submitting an answer does not load"
        end

        response1 = CheckState.job_by_user(job_id, username)
        # @driver.save_screenshot("#{response1.parsed_response["question_state"]["question"]["id"]}.png")

        # puts  "\n\n\n\n\n\nthe state after submitting\n\n\n\n\n\n"
        # ap response1.parsed_response
        # puts  "\n\n\n\n\n\nthe end\n\n\n\n\n\n"
        i=1
        while response1.parsed_response.has_key? ("stacktrace") && i < 4 do
          puts "\n\n\n\n\n\n\n\n\nit failed #{i} times\n\n\n\n\n\n\n\n\n"
          ap response1.parsed_response
          response1 = CheckState.job_by_user(job_id, username)
          sleep 2
          i += 1
        end

        begin
          if response1.parsed_response["question_state"]["question"]["id"] == response.parsed_response["question_state"]["question"]["id"]
            sleep 4
            response1 = CheckState.job_by_user(job_id, username)
          else
            # puts "\n\n\nchecked and its not the same\n\n\n"
          end
        rescue
        end

        # puts "\n\nThe State after submitting the answer is \n"
        # ap response1.parsed_response["application_state"]

        response1.parsed_response["application_state"]
      else
        # puts @driver.page_source
        return "COMPLETED"
      end
    end
  end

end

