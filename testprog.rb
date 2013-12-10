require "selenium-webdriver"

#Firefox browser instantiation
driver = Selenium::WebDriver.for :firefox

#Loading the assertselenium URL
driver.navigate.to "http://www.assertselenium.com"

#Clicking on the Follow link present on the assert selenium home page
FollowButton  = driver.find_element(:link, "Follow")
FollowButton.click

#Typing the UserName
LoginButton = driver.find_element(:id, "user_login")
LoginButton.send_keys "sampleuser77dff27"

#Typing the Email-Id
EmailId = driver.find_element(:id, "user_email")
EmailId.send_keys "sampleuser7f7df27@gmail.com"

#Clicking on the Submit Button
SubmitButton = driver.find_element(:id, "wp-submit")
SubmitButton.click
FindButton = driver.find_element(:xpath, "//button[@type='submit']")
FindButton.click
#Asserting whether the registration success message is diaplyed
SuccessMessage = driver.find_element(:css, "p.message")
"Registration complete. Please check your e-mail.".eql? SuccessMessage.text
puts "Successfully completed the user registration and validated the Success message"

#Quitting the browser
driver.quit