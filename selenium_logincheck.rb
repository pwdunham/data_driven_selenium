
# housekeeping
# e.methods.sort

require "selenium-webdriver"
# Open a browser
s = Selenium::WebDriver.for :firefox

# Navigate to a url
# s.get "http://www.google.com"


# Save a screenshot
# s.save_screenshot("google.png")


# Finding one element (raises exception when element not found)
# s.find_element(:css, "input[name='q']")


# Find multiple elements (notice: "s" at the end of the method name)
# s.find_elements(:css, "input")


# Clear the text out of a field
# s.find_element(:css, "input[name='q']").clear


# Simulate actual typing (Note: usually don't need this)
# s.find_element(:css, "input[name='q']").send_keys "jibe"


# Click an element
# s.find_element(:css, "button[name='btnG']").click

#navigate to Activision
s.get "http://activision.staging.jibeapply.com"

#click a line for a job
s.find_element(:css, "td[class='job-title']").click

# click the apply link
s.find_element(:css, "a[class='job-apply']").click

# switch to a frame
 s.switch_to.frame("mirrorFrame")


 #set the User name
 s.find_element(:css, "input[id='username']").send_keys "jibe_tester_activision"

  #set the password

 s.find_element(:css, "input[id='password']").send_keys "jibejibe1124"

 #click the submit button
 s.find_element(:css, "button[name='submit']").click

 #are we on the upload-welcome page?
 s.find_element(:css, "span[class='upload-welcome']").text.include?("Thank")
 s.find_element(:css, "span[class='pull-right logged-in-msg ng-binding']").text.include?("Logged in as")
