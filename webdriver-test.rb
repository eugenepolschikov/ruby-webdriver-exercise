require 'rubygems'
require 'selenium-webdriver'
require 'test/unit'

class SeleniumDemoTests  < Test::Unit::TestCase

  SEARCH_QUERY = "web"

  def test_end_to_end_test_flow

    # driver = Selenium::WebDriver.for :chrome
    driver = Selenium::WebDriver.for :chrome, switches: %w[--incognito]
    driver.manage.delete_all_cookies
    driver.navigate.to "http://www.upwork.com"
    driver.manage.window.maximize
    wait = Selenium::WebDriver::Wait.new(:timeout => 10) # seconds
    puts "Page title is #{driver.title}"
    puts "test debug"
    puts "test debug"
    search_freelancers_agencies_input = wait.until { driver.find_element(:name, "q") }
    search_freelancers_agencies_input.click
    #### search_freelancers_agencies_input = driver.find_element(:name, "q")
    search_freelancers_agencies_input.send_keys(SEARCH_QUERY)
    magnifying_glass_button = wait.until { driver.find_element(:css, "button[type='submit'][aria-label='Search']") }
    magnifying_glass_button.click

    magnifying_glass_button.submit
    wait.until { driver.title.downcase.start_with? "web - Upwork" }
    puts "Page title is #{driver.title}"
    driver.quit

  end
end