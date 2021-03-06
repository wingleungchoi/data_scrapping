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
  return @stocks_data_collection #  an array of Nokogiri::XML::Element
end


def purify_data(collection_raw_data) # only accepts stocks_data_collection which is a return of collecion_raw_dat and makes it pure i.e. remove depulicates and make all elements string
  no_chinese_data = [] # remove chinese words of year, month, day and convert to '-'
  collection_raw_data.each do |element|
    no_chinese_data << element.text.strip.tr('年','-').tr('月','-').tr('日','')
  end

  td_to_delete = [] #  a container for depulicate data due to giving dividend and special stock dividend 
  no_chinese_data.each_index do |index|
      if /股利/.match(no_chinese_data[index])
        td_to_delete << no_chinese_data[index - 1]
        td_to_delete << no_chinese_data[index]
      end
      if /股票分拆/.match(no_chinese_data[index])
        td_to_delete << no_chinese_data[index - 1]
        td_to_delete << no_chinese_data[index]
      end
  end
 # remove depulicate data 
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
  return no_chinese_data  # an array of string elements  which is [2012-04-11, 28.800, 28.800, 28.150, 28.650, 3,113,400, 26.540, another day........]
end

  NUMBER_OF_MISSING_STOCK = [49, 80, 134, 140, 150,153, 192, 203, 249, 284, 288, 301, 304, 314, 324, 325, 331, 344, 349, 394, 400, 401, 407, 409, 414, 415, 416, 424, 427, 429, 434, 436, 437, 441, 442, 443, 446, 447, 448, 452, 453, 454, 457, 461, 462, 463, 466, 470, 473, 478, 481, 484, 490, 492]
=begin  # the way to find missing stock number or stocks cannot provide sufficient data
  (100..500).each do |number|
    begin
    stock_number =  "0" + number.to_s
    puts purify_data(collection_raw_data(stock_number)).length.to_s + " " + number.to_s
    rescue 
      NUMBER_OF_MISSING_STOCK << number
    end
  end
=end 



