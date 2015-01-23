require 'rubygems'
require 'mechanize'
require 'pry'

  def download_data_from_yahoo(page, target_css=".yfnc_tabledata1" )
    parseable_page = page.parser
    stocks_data = parseable_page.css(target_css).to_a
     #remove last element which is a chinese word
    stocks_data.pop
    return stocks_data  
  end

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
  stocks_data_collection = [] # an array of Nokogiri::XML::Element

  stocks_data_collection += download_data_from_yahoo(page)

  10.times do   # only 10 times to prevent database overload
    page = agent.page.link_with(:text => '下一頁').click 
    stocks_data_collection += download_data_from_yahoo(page)
  end
  return stocks_data_collection #  an array of Nokogiri::XML::Element
end


def purify_data(stock_number) # only accepts a string of 4 digits as an argument. and return it pure data i.e. remove depulicates and make all elements string
  stocks_data_collection = collection_raw_data(stock_number)
  no_chinese_data = [] # remove chinese words of year, month, day and convert to '-'
  no_chinese_data = collection_raw_data.map{|element| element.text.strip.gsub(/[年月]/, "-").gsub(/[日]/,'')}

  td_to_delete = [] #  a container for depulicate data due to giving dividend and special stock dividend 
  no_chinese_data.each_index do |index|
      if /股利|股票分拆/.match(no_chinese_data[index])
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
    puts purify_data(stock_number).length.to_s + " " + number.to_s
    rescue 
      NUMBER_OF_MISSING_STOCK << number
    end
  end
=end 

def data_packed_in_day(stock_number) # only accepts a string of 4 digits as an argument. each hash is {date: "2012-04-11",open: "28.800", high: "28.800", low: "28.150", close: "28.650", trading_volume: "3,113,4000", adjusted_close: "26.540"}
  purified_data = purify_data(stock_number)
  days_of_record = purified_data.length/7
  number_started_by_zero = days_of_record - 1
  data_in_days = []
  (0..number_started_by_zero).each do |number|
    data_in_days[number] = {}
    data_in_days[number][:date] = purified_data[number*7]
    data_in_days[number][:open] = purified_data[number*7 + 1]
    data_in_days[number][:high] = purified_data[number*7 + 2]
    data_in_days[number][:low] = purified_data[number*7 +3]
    data_in_days[number][:close] = purified_data[number*7 +4]
    data_in_days[number][:trading_volume] = purified_data[number*7 + 5]
    data_in_days[number][:adjusted_close] = purified_data[number*7 + 6]
  end
  return data_in_days # returns an array of hashs
end

puts data_packed_in_day("2388")
puts data_packed_in_day("2388").length