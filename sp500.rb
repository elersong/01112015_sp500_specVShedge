require 'pry'
require 'nokogiri'
require 'open-uri'
require 'csv'
# ============================================================================== Pseudocode Algorithm
#
# 1.  Iterate over list of stocks to grab each one individually
# 2.  Find out if stock is optionable
# 3.  If optionable, get the in-the-money break price to use as std of comparison
# 4.  For all Calls get 3 strike price and open interest contracts higher and lower than break
# 5.  Do the same for puts
# 6.  Save both as rows on a daily csv file
# 7.  Add the total of all 12 open interest contracts to a rolling sum that will accumulate
#     all contract totals for all stocks.
# 8.  Get 3 strike price and open interest contracts higher and lower than break 
#     for calls and puts on S&P 500. Add them together.
# 9.  Save both the totals in a csv file that will have "index", "composite", and
#     "date" columns. Make sure it's appended rather than cleared and overwritten.
# 10. Run this algorithm daily
#
# ============================================================================== Class / Method Definitions

STOCKS = CSV.read('sp500_companies.csv')
BASE_URI = "http://finance.yahoo.com/q/op?s=[symbol]&straddle=true&date=[exp_date]"
EXP_DATE = 1421452800 # converted to epoch time

class Stock
  attr_accessor :symbol, :name, :sector, :yhoo_uri, :calls_contracts_around_money, :puts_contracts_around_money
    
  def initialize(array)
    @symbol = array[0]
    @name = array[1]
    @sector = array[2]
    @yhoo_uri = BASE_URI.gsub("[symbol]", @symbol).gsub("[exp_date]",EXP_DATE.to_s)
    @calls_contracts_around_money = get_calls_around_money_open_interest
    @puts_contracts_around_money = get_puts_around_money_open_interest
  end
  
  def is_optionable?
    yhoo_options_page = Nokogiri::HTML(open(self.yhoo_uri)) 
    yhoo_options_page.css('.in-the-money').empty? ? false : true
  end
  
  def get_calls_around_money_open_interest
    yhoo_options_page = Nokogiri::HTML(open(self.yhoo_uri)) 
    table_rows_even = yhoo_options_page.css('table tr.even')
    table_rows_odd = yhoo_options_page.css('table tr.odd')
    open_interest_contracts_array = [[],[]] # in_money, near_money
    
    all_rows = table_rows_even.each_with_index.map do |row, index|
      [row, table_rows_odd[index]]
    end.flatten
    
    next_rows = 3 #how many clicks out of the money to collect data for
    all_rows.each do |row|
      next if row.nil?
      in_money = row.css('td:nth-child(6).in-the-money').text.strip 
      near_money = row.css('td:nth-child(6)').text.strip
      start_counting_near_money = true
      
      unless in_money.empty?
        #puts in_money
        open_interest_contracts_array[0] << in_money.to_i
        start_counting_near_money = false
        next_rows = 2 # reset if iterator hits another in-the-money row on the way down the table
        open_interest_contracts_array[1] = [] # reset the near-the-money array too
      end
      
      if start_counting_near_money && next_rows >= 0
        #binding.pry
        next_rows -= 1
        #puts near_money
        open_interest_contracts_array[1] << near_money.to_i
        #puts "^ near the money"
      end
    end
    
    if open_interest_contracts_array[0].count < 3
      len = open_interest_contracts_array[0].count
      return [open_interest_contracts_array[0][-len..-1],open_interest_contracts_array[1]]
    else
      return [open_interest_contracts_array[0][-3..-1],open_interest_contracts_array[1]]
    end
  end
  
  def get_puts_around_money_open_interest
    yhoo_options_page = Nokogiri::HTML(open(self.yhoo_uri)) 
    table_rows_even = yhoo_options_page.css('table tr.even')
    table_rows_odd = yhoo_options_page.css('table tr.odd')
    open_interest_contracts_array = [[],[]] # in_money, near_money
    
    all_rows = table_rows_even.each_with_index.map do |row, index|
      [row, table_rows_odd[index]]
    end.flatten
    
    next_rows = 3 #how many clicks out of the money to collect data for
    stop_counting_near_money = false
    
    all_rows.each do |row|
      next if row.nil?
      in_money = row.css('td:nth-child(12).in-the-money').text.strip 
      near_money = row.css('td:nth-child(12)').text.strip
      start_counting_in_money = true
      
      if in_money.empty? && !stop_counting_near_money
        open_interest_contracts_array[1] << near_money.to_i
        start_counting_in_money = false
        next_rows = 2 # reset if iterator hits another near-the-money row on the way down the table
        open_interest_contracts_array[0] = [] # reset the in-the-money array too
      end
      
      if start_counting_in_money && next_rows >= 0
        next_rows -= 1
        open_interest_contracts_array[0] << in_money.to_i
        stop_counting_near_money = true # once iterator hits in-the-money stop adding to near-money ary
      end
    end
    
    if open_interest_contracts_array[0].count < 3 && open_interest_contracts_array[1].count < 3
      len1 = open_interest_contracts_array[0].count
      len2 = open_interest_contracts_array[1].count
      return [open_interest_contracts_array[0][-len1..-1],open_interest_contracts_array[1][-len2..-1]]
      
    elsif open_interest_contracts_array[1].count < 3
      len = open_interest_contracts_array[0].count
      return [open_interest_contracts_array[0][-3..-1],open_interest_contracts_array[1][-len..-1]]
      
    else
      return [open_interest_contracts_array[0][-3..-1],open_interest_contracts_array[1][-3..-1]]
    end
  end
  
  def sum_of_calls
    @calls_contracts_around_money.flatten.grep(Integer).inject(0) { |sum,x| sum + x }
  end
  
  def sum_of_puts
    @puts_contracts_around_money.flatten.grep(Integer).inject(0) { |sum,x| sum + x }
  end
    
end

class StockFile
  @today = (Date.today).strftime('%Y-%m-%d')
  
  def self.details_around_money_append(stock_object) # <= Object
    CSV.open("daily_details_around_the_money.csv", "a+") do |daily_details|
      call_info = []
      call_info << @today
      call_info << stock_object.symbol
      
      stock_object.calls_contracts_around_money.flatten.each do |number|
        call_info << number
      end
      
      put_info = []
      put_info << @today
      put_info << stock_object.symbol
      
      stock_object.puts_contracts_around_money.flatten.each do |number|
        put_info << number
      end
      
      daily_details << call_info
      daily_details << put_info
    end
  end
  
  def self.daily_sums_append(stock_object)
    CSV.open("daily_sums_per_symbol.csv", "a+") do |daily_sums|
      new_row = []
      new_row << @today
      new_row << stock_object.symbol
      new_row << (stock_object.sum_of_calls + stock_object.sum_of_puts)
      
      daily_sums << new_row
    end
  end
  
end

class ProgressBar
  
  def initialize(number_for_completion)
    @number_total = number_for_completion.to_f
    @completed_number = 0
  end
  
  def increment_and_show_bar
    @completed_number += 1
    progress_string = "["
    percentage_complete = (@completed_number/@number_total * 100).to_i
    
    100.times do |iteration|
      if iteration <= percentage_complete
        progress_string << "="
      else
        progress_string << " "
      end
    end
    
    progress_string << "] #{percentage_complete}%"
    
    puts progress_string
  end
  
end

# ============================================================================== Program Logic

progress = ProgressBar.new STOCKS.count
last_stock = ["","","","","",""]

STOCKS.each do |stock|
  
  puts "#{last_stock[0]} (#{last_stock[1]})"
  puts last_stock[2].inspect
  puts last_stock[3].inspect
  puts "calls: #{last_stock[4]}"
  puts "puts: #{last_stock[5]}"
  puts ""
  
  last_stock = []
  progress.increment_and_show_bar 
  
  # slow down process so that responses don't get interrupted by servers
  sleep 2
  one_stock = Stock.new(stock)
  
  last_stock << one_stock.name
  last_stock << one_stock.symbol
  last_stock << one_stock.calls_contracts_around_money
  last_stock << one_stock.puts_contracts_around_money
  last_stock << one_stock.sum_of_calls
  last_stock << one_stock.sum_of_puts
  
  StockFile.details_around_money_append one_stock
  StockFile.daily_sums_append one_stock
  system("clear")
end
