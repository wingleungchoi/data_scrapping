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
 # td_to_delete is array of depulicated strings [date, 股利, date,股票分拆, date,股利, date,股利 ....]
 # element even index, e.g. 0,2,4, in td_to_delete is the depulicate date
 # element odd incdex, in  td_to_delete is the depulicate chinese 股利|股票分拆
 # chinese 股利|股票分拆 is unique, therefore, it is confident to remove them by just using method delete
 # however depulicate dates cannot simply use delete() method
 # because depulicate dates somethings might be present twice in data if the company gives dividend on a trading day
 # line 70 to find whether it is present twice. 
 # if present twice, we cannot use delete method
  td_to_delete.each_index do |index|
    if index%2 == 0 && no_chinese_data.uniq.include?(td_to_delete[index]) 
        no_chinese_data.delete(td_to_delete[index]) # simlply used delete because the depulcate date only is present once
      elsif index%2 == 0 
         binding.pry
        no_chinese_data.delete_at(no_chinese_data.index(td_to_delete[index]) - 7) 
        # find to the real index of the depulicate date which is 1 table row / 7 table data before fake index because the depulcate date only is twice
      else
        no_chinese_data.delete(td_to_delete[index])
        # chinese 股利|股票分拆 is unique, therefore, it is confident to remove them by just using method delete
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

def data_packed_in_day(purify_data) # only accepts purify_data and returns an array of hashs. each hash is {date: "2012-04-11",open: "28.800", high: "28.800", low: "28.150", close: "28.650", trading_volume: "3,113,4000", adjusted_close: "26.540"}
  days_of_record = purify_data.length/7
  number_started_by_zero = days_of_record - 1
  data_in_days = []
  (0..number_started_by_zero).each do |number|
    data_in_days[number] = {}
    data_in_days[number][:date] = purify_data[number*7]
    data_in_days[number][:open] = purify_data[number*7 + 1]
    data_in_days[number][:high] = purify_data[number*7 + 2]
    data_in_days[number][:low] = purify_data[number*7 +3]
    data_in_days[number][:close] = purify_data[number*7 +4]
    data_in_days[number][:trading_volume] = purify_data[number*7 + 5]
    data_in_days[number][:adjusted_close] = purify_data[number*7 + 6]
  end
  return data_in_days # returns an array of hashs
end

puts data_packed_in_day(purify_data(collection_raw_data("2388")))