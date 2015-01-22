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


def purify_data(collection_raw_data) # only accepts stocks_data_collection which is a return of collecion_raw_dat and makes it pure i.e. remove depulicates and make all elements string
  no_chinese_data = []
  collection_raw_data.each do |element|
    no_chinese_data << element.text.strip.tr('年','-').tr('月','-').tr('日','')
  end

  td_to_delete = [] # remove depulicate data of giving dividend
  no_chinese_data.each_index do |index|
      if /股利/.match(no_chinese_data[index])
        td_to_delete << no_chinese_data[index - 1]
        td_to_delete << no_chinese_data[index]
      end
  end
 # remove depulicate data of giving dividend
  td_to_delete.each_index do |index|
    if index%2 == 0 && no_chinese_data.uniq.include?(td_to_delete[index])
        no_chinese_data.delete_at(no_chinese_data.index(td_to_delete[index]))
      elsif index%2 == 0 
         binding.pry
        no_chinese_data.delete_at(no_chinese_data.index(td_to_delete[index]) - 7)
      else
        no_chinese_data.delete(td_to_delete[index])
    end
  end
  binding.pry
  return no_chinese_data  
end
puts purify_data(collection_raw_data("0001")).length

