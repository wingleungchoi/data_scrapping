require 'rubygems'
require 'mechanize'

url = "https://hk.finance.yahoo.com/q/hp?s=0388.HK "
agent = Mechanize.new
page = agent.get(url).parser
target_css = ".yfnc_tabledata1"
stocks_data = page.css(target_css).to_a
 #remove last element
 stocks_data.pop

def remove_chinese_characters(some_string)
    some_string.tr('年','-').tr('月','-').tr('日','')
end 

 pure_data = []
 stocks_data.each do |data_element|
   pure_data << remove_chinese_characters(data_element.text.strip)
 end

 puts pure_data

