require 'rubygems'
require 'selenium-webdriver'
require 'test/unit'
require 'json'

class SeleniumDemoTests < Test::Unit::TestCase

  SEARCH_QUERY = ARGV[0]
  WAIT_INTERVAL_DEFAULT = 10
  ARGS_NUM = ARGV.length

  def test_end_to_end_test_flow

    page_objs = File.read('./page-objects.json')
    data_hash = JSON.parse(page_objs)

    if ARGS_NUM > 1 || ARGS_NUM == 0
      puts "invalid args number"
      exit
    end
    puts "Working on #{SEARCH_QUERY}"

    # driver = Selenium::WebDriver.for :chrome
    driver = Selenium::WebDriver.for :chrome, switches: %w[--incognito]
    driver.manage.delete_all_cookies
    driver.manage.window.maximize
    driver.navigate.to "http://www.upwork.com"
    # sleep 165
    wait = Selenium::WebDriver::Wait.new(:timeout => WAIT_INTERVAL_DEFAULT) # seconds
    puts "Page title is #{driver.title}"
    search_freelancers_agencies_input = wait.until { driver.find_element(:name, data_hash['landing']['searchInputName']) }
    search_freelancers_agencies_input.click

    search_freelancers_agencies_input.send_keys(SEARCH_QUERY)
    magnifying_glass_button = wait.until { driver.find_element(:css, data_hash['landing']['magnifyingGlassButtonCss']) }
    magnifying_glass_button.click

    wait_second = Selenium::WebDriver::Wait.new(:timeout => WAIT_INTERVAL_DEFAULT) # seconds
    wait_second.until { driver.title.downcase.start_with? SEARCH_QUERY }
    puts "Page title is #{driver.title}"
    driver.quit

  end
end