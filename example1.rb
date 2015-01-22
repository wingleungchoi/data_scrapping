require 'mechanize'

# Create a new instance of Mechanize and grab our page
agent = Mechanize.new  
page = agent.get('http://cat-training-course.heroku.com/')

# Find all the links on the page that are contained within
# h1 tags.
post_links = page.links.find_all { |l| true }

# Click on one of our post links and store the response
post = post_links[0].click  
doc = page.parser # Same as Nokogiri::HTML(page.body)  
p doc