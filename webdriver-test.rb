require 'rubygems'
require 'selenium-webdriver'
require 'test/unit'

class SeleniumDemoTests  < Test::Unit::TestCase

  SEARCH_QUERY = "web"

  def test_end_to_end_test_flow

    # driver = Selenium::WebDriver.for :chrome
    driver = Selenium::WebDriver.for :chrome, switches: %w[--incognito]
    driver.manage.delete_all_cookies
    driver.manage.window.maximize
    driver.navigate.to "http://www.upwork.com"
    # sleep 65
    wait = Selenium::WebDriver::Wait.new(:timeout => 10) # seconds
    puts "Page title is #{driver.title}"
    search_freelancers_agencies_input = wait.until { driver.find_element(:name, "q") }
    search_freelancers_agencies_input.click

    search_freelancers_agencies_input.send_keys(SEARCH_QUERY)
    magnifying_glass_button = wait.until { driver.find_element(:css, "button[type='submit'][aria-label='Search']") }
    magnifying_glass_button.click

    wait_second = Selenium::WebDriver::Wait.new(:timeout => 10) # seconds
    wait_second.until { driver.title.downcase.start_with? "web" }
    puts "Page title is #{driver.title}"
    driver.quit

  end
end