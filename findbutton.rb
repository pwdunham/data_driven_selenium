require "selenium-webdriver"

#Firefox browser instantiation
driver = Selenium::WebDriver.for :firefox

#Loading the assertselenium URL
driver.navigate.to "http://fluor.staging.jibeapply.com"
FindButton = driver.find_element(:xpath, "//button[@type='submit']")
FindButton.click