require 'rubygems'
require 'selenium-webdriver'
require 'test/unit'
require 'json'

class SeleniumDemoTests < Test::Unit::TestCase

  BASE_URL = "http://www.upwork.com"
  SEARCH_QUERY = ARGV[0]
  WAIT_INTERVAL_DEFAULT = 10
  ARGS_NUM = ARGV.length

  #### Starting browser before each test
  def setup
    # @browser = Selenium::WebDriver.for :firefox
    # @browser.get "http://localhost/page8"
    # @wait = Selenium::WebDriver::Wait.new(:timeout => 15)
    #
    #
    #
    #
    # creating chrome instance on default settings/capabilities.
    # driver = Selenium::WebDriver.for :chrome
    @driver = Selenium::WebDriver.for :chrome, switches: %w[--incognito]
    @driver.manage.delete_all_cookies
    @driver.manage.window.maximize
    puts "opening website '#{BASE_URL}'"
    @driver.navigate.to "#{BASE_URL}"
    @page_objs = File.read('./page-objects.json')
    @data_hash = JSON.parse(@page_objs)

    #this extra sleep is needed if captcha needs to be handled manually
    # sleep 165
  end

  #### Closing browser after each test
  def teardown
    @driver.quit
  end

  def test_end_to_end_test_flow

    if ARGS_NUM > 1 || ARGS_NUM == 0
      puts "invalid args number"
      exit
    end
    puts "Working on #{SEARCH_QUERY}"

    wait = Selenium::WebDriver::Wait.new(:timeout => WAIT_INTERVAL_DEFAULT) # seconds
    puts "wait for the element with locator '#{@data_hash['landing']['searchInputName']}' on the page '#{@driver.current_url}'"
    search_input = wait.until { @driver.find_element(:name, @data_hash['landing']['searchInputName']) }
    puts "clicking on the element with locator '#{@data_hash['landing']['searchInputName']}' on the page '#{@driver.current_url}'"
    search_input.click

    puts "entering '#{SEARCH_QUERY}' in search input defined by locator '#{@data_hash['landing']['searchInputName']}' on the page '#{@driver.current_url}'"
    search_input.send_keys(SEARCH_QUERY)
    magnifying_glass_button = wait.until { @driver.find_element(:css, @data_hash['landing']['magnifyingGlassButtonCss']) }
    puts "clicking on magnifying glass button defined by locator '#{@data_hash['landing']['magnifyingGlassButtonCss']}' on the page '#{@driver.current_url}'"
    magnifying_glass_button.click

    # wait_second = Selenium::WebDriver::Wait.new(:timeout => WAIT_INTERVAL_DEFAULT) # seconds
    # wait_second.until { @driver.title.downcase.start_with? SEARCH_QUERY }
    wait.until { @driver.title.downcase.start_with? SEARCH_QUERY }
    puts "checking that after clicking magnifying glass button - actual page title '#{@driver.title}' starts with '#{SEARCH_QUERY}'"

    # extracting freelancers from this first page.
    freelancers = Hash.new()
    freelances_names = @driver.find_elements(:css, 'div[data-qa-freelancer-ciphertext] button[itemprop=name]')
    freelancer_titles = @driver.find_elements(:css, 'div[data-qa-freelancer-ciphertext] p.freelancer-title')
    freelancer_overview = @driver.find_elements(:css, 'p.overview')
    freelanceer_skills = @driver.find_elements(:xpath, '//div[@class="up-skill-wrapper"][./div[contains(@class,up-skill-badge)]]')
    count = 0
    puts "analyzing found freelancers and checking for keyword '#{SEARCH_QUERY}' in all found freelancers' title, overview, skills"

    freelancer_titles.zip(freelancer_overview, freelanceer_skills).each do |title, overview, skill|
      # these two lines are for debugging. @TODO remove before creating a PR
      # puts "title:'#{title.text}'  overview: '#{overview.text}'"
      # freelancers[name.text] = title.text
      freelancers[freelances_names[count].text] = [title.text, overview.text, skill.text]

      if title.text.downcase.include? SEARCH_QUERY.downcase
        puts "fl '#{freelances_names[count].text}' title contains '#{SEARCH_QUERY}' keyword"
      else
        puts "fl '#{freelances_names[count].text}' title DOES NOT contain '#{SEARCH_QUERY}' keyword"
      end

      if overview.text.downcase.include? SEARCH_QUERY.downcase
        puts "fl '#{freelances_names[count].text}' overview contains '#{SEARCH_QUERY}' keyword"
      else
        puts "fl '#{freelances_names[count].text}' overview DOES NOT contain '#{SEARCH_QUERY}' keyword"
      end

      if skill.text.downcase.include? SEARCH_QUERY.downcase
        puts "fl '#{freelances_names[count].text}' skill contains '#{SEARCH_QUERY}' keyword"
      else
        puts "fl '#{freelances_names[count].text}' skill DOES NOT contain '#{SEARCH_QUERY}' keyword"
      end

      count += 1
    end

    puts "######## extracted #{count} freelancers ########"
    puts freelancers
    puts "#######"

    puts "clicking on random freelancer title"
    freelancer_titles.sample.click
    puts "wait for freelancer details page/widget opens"
    element = wait.until { @driver.find_element(:css => "div[tabindex='-1'][class='up-slider-content']") }

    sleep 5

    # driver.find_elements(:css, 'div[data-qa-freelancer-ciphertext]').each do |div|
    #   # puts div.attribute_value("data-channel")
    #   # puts div.text
    #   # puts div.text
    #   puts (div.find_element("[itemprop='name']")).text
    # end
  end
end