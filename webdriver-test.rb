require 'rubygems'
require 'selenium-webdriver'
require 'test/unit'
require 'json'

class SeleniumDemoTests < Test::Unit::TestCase

  BASE_URL = "http://www.upwork.com"
  SEARCH_QUERY = ARGV[0]
  BROWSER = ARGV[1]
  WAIT_INTERVAL_DEFAULT = 15
  ARGS_NUM = ARGV.length
  FREELANCERS_TITLE_KEY = 'title'
  FREELANCERS_OVERVIEW_KEY = 'overview'
  FREELANCERS_SKILLS_KEY = 'skills'
  SUBSTRING_LENGTH = 40

  #### Starting browser before each test
  def setup

    if BROWSER == "chrome"
      @driver = Selenium::WebDriver.for :chrome, switches: %w[--incognito]
    elsif BROWSER == "firefox"
      @driver = Selenium::WebDriver.for :firefox
    else
      puts "invalid browser name"
      exit
    end
    @driver.manage.delete_all_cookies
    @driver.manage.window.maximize
    puts "opening website '#{BASE_URL}'"
    @driver.navigate.to "#{BASE_URL}"
    @page_objs = File.read('./page-objects.json')
    @data_hash = JSON.parse(@page_objs)

    # this extra sleep is needed if captcha needs to be handled manually
    # sleep 165
  end

  #### Closing browser after each test
  def teardown
    @driver.quit
  end

  def test_end_to_end_test_flow

    if ARGS_NUM > 2 || ARGS_NUM == 0
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

    # creating nested hash to extract data from frelancers list (search resutls) page.
    freelancer_titles.zip(freelancer_overview, freelanceer_skills).each do |title, overview, skill|
      freelancers[freelances_names[count].text] = Hash.new()
      freelancers[freelances_names[count].text][FREELANCERS_TITLE_KEY] = title.text
      freelancers[freelances_names[count].text][FREELANCERS_OVERVIEW_KEY] = overview.text
      freelancers[freelances_names[count].text][FREELANCERS_SKILLS_KEY] = skill.text

      check_and_output_comparison_result(title.text.downcase, SEARCH_QUERY, "fl '#{freelances_names[count].text}' title ")
      check_and_output_comparison_result(overview.text.downcase, SEARCH_QUERY, "fl '#{freelances_names[count].text}' overview ")
      check_and_output_comparison_result(skill.text.downcase, SEARCH_QUERY, "fl 'fl '#{freelances_names[count].text}' skill ")
      count += 1
    end

    puts "######## extracted #{count} freelancers ########"
    # removed to avoid excessive logging
    # puts freelancers
    # puts "#######"

    puts "extracting random freelancer title from titles webelement list to apply random click on it"
    webelement_random_fl_title = freelancer_titles.sample
    puts "clicking on extracted freelancer title '#{webelement_random_fl_title.text}'"
    webelement_random_fl_title.click
    # hardcoded wait to be sure freelancer details page loaded
    sleep 5

    # verification of steps 10,11
    # check that each attrubute value is equal to one of those stored in the structure 'freelancers'
    # check whether at least one attribute contains <keyword>
    puts "wait for freelancer details page/widget opens"
    wait.until { @driver.find_element(:css => @data_hash['freelancer_profile']['fl_details_popup']) }
    name = wait.until { @driver.find_element(:css => @data_hash['freelancer_profile']['name']) }
    single_freelancer_title = wait.until { @driver.find_element(:css => @data_hash['freelancer_profile']['title']) }
    single_freelancer_overview = wait.until { @driver.find_element(:css => @data_hash['freelancer_profile']['overview']) }
    single_fl_skills_webelements = wait.until { @driver.find_elements(:css => @data_hash['freelancer_profile']['skills_list']) }
    puts "extracting the data for opened freelancer with name '#{name.text}'"

    if freelancers.has_key? name.text
      # removed due to excessive logging
      # puts "FREELANCER TITLE from freelancer list page '#{freelancers[name.text][FREELANCERS_TITLE_KEY]}'"
      # puts "FREELANCER OVERVIEW from freelancer list page '#{freelancers[name.text][FREELANCERS_OVERVIEW_KEY]}'"
      # puts "FREELANCER SKILLS from freelancer list page '#{freelancers[name.text][FREELANCERS_SKILLS_KEY]}'"
      # puts "ACTUAL name from single freelancer page: '#{name.text}'"
      # puts "ACTUAL title from single freelancer page: '#{single_freelancer_title.text}'"
      # puts "ACTUAL overview from single freelancer page: '#{single_freelancer_overview.text}'"

      assert_for_fl_vals(single_freelancer_title.text, freelancers[name.text][FREELANCERS_TITLE_KEY], "actual freelancer title does not in match with title of freelancer from freelancer list page")
      check_and_output_comparison_result(single_freelancer_title.text, SEARCH_QUERY, "freelancer '#{name.text}' title ")

      assert_for_fl_vals(single_freelancer_overview.text.tr("\n", "")[0, SUBSTRING_LENGTH], freelancers[name.text][FREELANCERS_OVERVIEW_KEY].tr("\n", "")[0, SUBSTRING_LENGTH], "actual freelancer title does not in match with title of freelancer from freelancer list page")
      check_and_output_comparison_result(single_freelancer_overview.text, SEARCH_QUERY, "freelancer '#{name.text}' overview ")

      # less rigoroous check whether at least one attribute contains <keyword>
      if (single_freelancer_title.text.include? SEARCH_QUERY) || (single_freelancer_overview.text.include? SEARCH_QUERY) || (checking_query_for_webelements(single_fl_skills_webelements, SEARCH_QUERY))
        puts "at least either TITLE or OVERVIEW or SKILLS for FL '#{name.text}' contains '#{SEARCH_QUERY}'"
      else
        puts "NEITHER title NOR overview NOR skills for FL '#{name.text}' contains '#{SEARCH_QUERY}'"
      end

    else
      throw Exception("was not able to find freelancer '#{name.text}' amongst previously extracted data '#{freelancers}'")
    end

  end

  def check_and_output_comparison_result(actual_value, query_to_lookup, log_message)
    if actual_value.include? query_to_lookup
      puts "#{log_message} contains '#{query_to_lookup}' keyword"
    else
      puts "#{log_message} DOES NOT contain '#{query_to_lookup}' keyword"
    end
  end

  def assert_for_fl_vals(actual_value, expected, log_message)
    puts "ACTUAL: '#{actual_value}', EXPECTED: '#{expected}'"
    assert_equal(expected, actual_value, log_message)
  end

  def checking_query_for_webelements(webelement_list, query)
    skills_contains_query_flag = false
    webelement_list.each do |singLe_skill|
      if singLe_skill.text.include? query
        # removed due to excessive logging
        # puts "checking whether webelement '#{singLe_skill.text}' contains query'#{query}'"
        skills_contains_query_flag = true
        break
      end
    end
    return skills_contains_query_flag
  end
end