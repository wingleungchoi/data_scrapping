require 'rubygems'
require 'mechanize'
require 'pry'

def collection_raw_data(stock_number="0001")# it only accpet a string of 4 digits as an argument. In the end, it returns stocks_data_collection = [] # an array of Nokogiri::XML::Element
  url = "https://hk.finance.yahoo.com/q/hp?s=#{stock_number}.HK "
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


  download_data_from_yahoo(page)

  10.times do   # only 10 times to prevent database overload
    page = agent.page.link_with(:text => '下一頁').click 
    download_data_from_yahoo(page)
  end
  return @stocks_data_collection
end

no_chinese_data = []
collection_raw_data("0001").each do |element|
  no_chinese_data << element.text.strip.tr('年','-').tr('月','-').tr('日','')
end

no_chinese_data.delete_if {|data| /股利/.match(data) } # remove depulicate data eg 2014-09-01  股利


number_to_delete = [] # remove depulicate data of giving dividend
no_chinese_data.each_index do |index|
#  binding.pry
  if index < no_chinese_data.length - 7
    if no_chinese_data[index][0..2]=="201" && no_chinese_data[index+7][0..2]=="201" && no_chinese_data[index][-3..-1] == no_chinese_data[index+7][-3..-1]
      number_to_delete << index
    end
  end
end

number_to_delete.each do |element|
  no_chinese_data.delete_at(element)
end

puts no_chinese_data.length
