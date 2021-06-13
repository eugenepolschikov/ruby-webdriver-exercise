require 'rubygems'
require 'selenium-webdriver'
require 'test/unit'
require 'json'

class SeleniumDemoTests < Test::Unit::TestCase

  BASE_URL = "http://www.upwork.com"
  SEARCH_QUERY = ARGV[0]
  WAIT_INTERVAL_DEFAULT = 15
  ARGS_NUM = ARGV.length
  FREELANCERS_TITLE_KEY = 'title'
  FREELANCERS_OVERVIEW_KEY = 'overview'
  FREELANCERS_SKILLS_KEY = 'skills'

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

    wait.until { @driver.title.downcase.start_with? SEARCH_QUERY }
    puts "checking that after clicking magnifying glass button - actual page title '#{@driver.title}' starts with '#{SEARCH_QUERY}'"

    # extracting freelancers from this first page.
    freelancers = Hash.new()
    freelances_names = @driver.find_elements(:css, @data_hash['freelancer_search_results']['names'])
    freelancer_titles = @driver.find_elements(:css, @data_hash['freelancer_search_results']['titles'])
    freelancer_overview = @driver.find_elements(:css, @data_hash['freelancer_search_results']['overview'])
    freelanceer_skills = @driver.find_elements(:xpath, @data_hash['freelancer_search_results']['skills'])
    count = 0
    puts "analyzing found freelancers and checking for keyword '#{SEARCH_QUERY}' in all found freelancers' title, overview, skills"

    freelancer_titles.zip(freelancer_overview, freelanceer_skills).each do |title, overview, skill|
      #@TODO remove before pusjing to server
      # freelancers[freelances_names[count].text] = [title.text, overview.text, skill.text]
      freelancers[freelances_names[count].text] = Hash.new()
      freelancers[freelances_names[count].text][FREELANCERS_TITLE_KEY] = title.text
      freelancers[freelances_names[count].text][FREELANCERS_OVERVIEW_KEY] = overview.text
      freelancers[freelances_names[count].text][FREELANCERS_SKILLS_KEY] = skill.text

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

    puts "extracting random freelancer title"
    webelement_random_fl_title = freelancer_titles.sample
    puts "clicking on extracted freelancer title '#{webelement_random_fl_title.text}'"
    webelement_random_fl_title.click
    # hardcoded wait to ensure freelancer page/widget fully loads
    sleep 5

    # verification of steps 10,11
    # check that each attrubute value is equal to one of those stored in the structure 'freelancers'
    # check whether at least one attribute contains <keyword>
    puts "wait for freelancer details page/widget opens"
    wait.until { @driver.find_element(:css => @data_hash['freelancer_profile']['fl_details_popup']) }
    name = wait.until { @driver.find_element(:css => @data_hash['freelancer_profile']['name']) }
    single_freelancer_title = wait.until { @driver.find_element(:css => @data_hash['freelancer_profile']['title']) }
    puts "extracting the data for opened freelancer with name '#{name.text}'"

    if freelancers.has_key? name.text
      puts "FREELANCER TITLE from freelancer list page '#{freelancers[name.text][FREELANCERS_TITLE_KEY]}'"
      puts "FREELANCER OVERVIEW from freelancer list page '#{freelancers[name.text][FREELANCERS_OVERVIEW_KEY]}'"
      puts "FREELANCER SKILLS from freelancer list page '#{freelancers[name.text][FREELANCERS_SKILLS_KEY]}'"

      puts "ACTUAL name from single freelancer page: '#{name.text}'"
      puts "ACTUAL title from single freelancer page: '#{single_freelancer_title.text}'"

      puts "checking whether freelancer title is in match. ACTUAL: '#{single_freelancer_title.text}', EXPECTED: '#{freelancers[name.text][FREELANCERS_TITLE_KEY]}'"
      assert_equal(freelancers[name.text][FREELANCERS_TITLE_KEY], single_freelancer_title.text, "actual freelancer title does not in match with title of freelancer from freelancer list page")

    else
      throw Exception("was not able to find freelancer '#{name.text}' amongst previously extracted data '#{freelancers}'")
    end

  end
end