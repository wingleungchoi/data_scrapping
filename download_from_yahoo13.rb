require 'rubygems'
require 'mechanize'
require 'pry'

def remove_dividend_entries(trs) # input an array of trs (Nokogiri::XML::Element) and remove divident entries and return a new array of trs
  trs.each do |tr|
    # trs.delete(tr) if /股利|股票/.match(tr.text) Both work
    trs.delete(tr) if tr.children.length != 7
  end
  return trs
end

def remove_header_and_footer(trs) # input an array of trs (Nokogiri::XML::Element) and remove first and last element and return a new  array
  trs.shift
  trs.pop
  return trs
end

def download_table_rows_from_a_page(page) # input page (a object of Mechanize gem) and return an array of trs (Nokogiri::XML::Element) in one page
  parseable_page = page.parser
  table_rows_in_a_page = parseable_page.css("table#yfncsumtab").css("tr[valign='top']").css("table.yfnc_datamodoutline1").css("table[cellpadding='2']").css("tr")
  table_rows_in_a_page = table_rows_in_a_page.to_a # makes it acts like an array to facilitate following methods
  table_rows_in_a_page = remove_header_and_footer(table_rows_in_a_page) # remove first element 日期開市高低收市成交量調整後的收市價* and last element * 收市價已按股息和拆細而調整
  table_rows_in_a_page = remove_dividend_entries(table_rows_in_a_page)
end

=begin # the following lines is my test for method "download_table_rows_from_page"
  url = "https://hk.finance.yahoo.com/q/hp?s=0001.HK"
  agent = Mechanize.new
  page = agent.get(url)
  page = agent.page.link_with(:text => '下一頁').click 

  download_table_rows_from_a_page(page).to_a.each do |e|
    puts e.text
    puts e.class
  end
  puts download_table_rows_from_a_page(page).length
# puts download_table_rows_from_a_page(page) # target: [tr_object,tr_objec...]
# puts download_table_rows_from_a_page(page).length # taget 66 
=end 

def download_table_rows(stock_number)# input a string of 4 ditil and return an array of tr needed
  # assumption : yahoo default show data show from the day you search.
  url = "https://hk.finance.yahoo.com/q/hp?s=#{stock_number}.HK"
  agent = Mechanize.new
  page = agent.get(url)
  table_rows = []
  table_rows += download_table_rows_from_a_page(page)
  10.times do   # only 10 times to prevent database overload
    page = agent.page.link_with(:text => '下一頁').click 
    table_rows += download_table_rows_from_a_page(page)
  end 
  return table_rows 
end
#puts download_table_rows("0001").length  # target: 726 rows =  66 trs X 11 pages
#puts download_table_rows("0001") # target [tr_object,tr_objec...]

def translate_chinese_y_m_d_to_universal(date_in_chinese)
  return date_in_chinese.gsub(/[年月]/, "-").gsub(/[日]/,'')
end

def translate_volume_to_integer(volume_string)
  return volume_string.gsub(/[,]/, "").to_i
end

def make_tr_to_data(trs) # input an array of trs (Nokogiri::XML::Element) to return a array of hash where {date: "2012-04-11"(class: date),open: "28.800"(class: float), high: "28.800"(class: float), low: "28.150"(class: float), close: "28.650"(class: float), trading_volume: "3,113,4000"(class: integer), adjusted_close: "26.540"(class: float)}}
  sanitized_data = []
  a = []
  trs.each_index do |index|
    sanitized_data[index] = {}
    standardized_date = translate_chinese_y_m_d_to_universal( trs[index].children[0].text)
    integerified_trading_volume = translate_volume_to_integer(trs[index].children[5].text)
    sanitized_data[index][:date] =  Date.parse standardized_date
    sanitized_data[index][:open] = trs[index].children[1].text.to_f
    sanitized_data[index][:high] = trs[index].children[2].text.to_f
    sanitized_data[index][:low] = trs[index].children[3].text.to_f
    sanitized_data[index][:close] = trs[index].children[4].text.to_f
    sanitized_data[index][:trading_volume] = integerified_trading_volume
    sanitized_data[index][:adjusted_close] = trs[index].children[6].text.to_f
  end
  return sanitized_data
end



def download_from_yahoo(stock_number) #input a string of 4 ditil and return an array of hashs where each hash is a daily price like {date: 2015-01-05, high: 140,...}
  trs = download_table_rows(stock_number) # input a string of 4 ditil and return an array of tr (Nokogiri::XML::Element) needed
  return make_tr_to_data(trs) # input an array of tr and returnreturn an array of hashs where each hash is a daily price.
end

puts download_from_yahoo("0005")

NUMBER_OF_MISSING_STOCK = [49, 80, 133, 134, 140, 148, 150, 152, 153, 192, 203, 249, 258, 284, 288, 301, 302, 304, 314, 324, 325, 331, 338, 344, 349, 386, 394, 400, 401, 407, 409, 414, 415, 416, 424, 427, 429, 434, 436, 434, 436, 437, 441, 442, 443, 446, 447, 448, 452, 453, 454, 457, 460, 461, 462, 463, 466, 470, 473, 478, 481, 484, 490, 492]
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

=begin text of the method download_from_yahoo
  puts download_from_yahoo("0001").length #targe: 726
  puts download_from_yahoo("0005") # target: [{date: 2015-01-05, high: 140,...},{date: 2015-01-04,high:..},...]
=end
#PROBLEM_TR= [438, 42]
##  url = "https://hk.finance.yahoo.com/q/hp?s=0133.HK&a=0&b=12&c=2000&d=0&e=25&f=2015&g=d&z=66&y=396"
##  agent = Mechanize.new
##  page = agent.get(url)
##  parseable_page = page.parser
##  table_rows_in_a_page = parseable_page.css("table#yfncsumtab").css("tr[valign='top']").css("table.yfnc_datamodoutline1").css("table[cellpadding='2']").css("tr")
##  table_rows_in_a_page = table_rows_in_a_page.to_a # makes it acts like an array to facilitate following methods
##  table_rows_in_a_page = remove_header_and_footer(table_rows_in_a_page) # remove first element 日期開市高低收市成交量調整後的收市價* and last element * 收市價已按股息和拆細而調整
##  42.times do 
##    table_rows_in_a_page.shift
##  end
##  25.times do 
##    table_rows_in_a_page.pop
 # end