require 'rubygems'
require 'mechanize'
require 'open-uri'

url = "https://hk.finance.yahoo.com/q/hp?s=0388.HK "
puts open(url)
agent = Mechanize.new
page = agent.get('https://hk.finance.yahoo.com/q/hp?s=0388.HK').parser
puts page.css('.yfnc_tabledata1')
data = Nokogiri::HTML(open(url))
puts data.css('.yfnc_tabledata1').text.class
