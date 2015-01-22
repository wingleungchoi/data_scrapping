require 'rubygems'
require 'mechanize'

#in the end, it returns stocks_data_collection = [] # an array of Nokogiri::XML::Element


url = "https://hk.finance.yahoo.com/q/hp?s=0001.HK "
agent = Mechanize.new
page = agent.get(url)

yahoo_form = page.forms_with(action: '/q/hp')[1]

yahoo_form.b = '01'
yahoo_form.c = '2001'
yahoo_form.a = '01'

page = agent.submit(yahoo_form, yahoo_form.buttons.first) 
# now we are on the new page

# now confirm we search from 2001-01-01 to present #assume: yahoo default is present
#start scrapping data and store an array of Nokogiri::XML::Element
@stocks_data_collection = [] # an array of Nokogiri::XML::Element

def download_data_from_yahoo(page, target_css=".yfnc_tabledata1" )
  parseable_page = page.parser
  stocks_data = parseable_page.css(target_css).to_a
   #remove last element which is a chinese word
  stocks_data.pop
  @stocks_data_collection += stocks_data  
end


page = agent.page.link_with(:text => '下一頁').click  


download_data_from_yahoo(page)

5.times do   # only 5 times to prevent database overload
  page = agent.page.link_with(:text => '下一頁').click 
  download_data_from_yahoo(page)
end






