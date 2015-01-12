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

STOCKS = CSV.read('sp500_companies.csv').sample(1)
BASE_URI = "http://finance.yahoo.com/q/op?s=[symbol]&straddle=true&date=[exp_date]"
EXP_DATE = 1421452800

class Stock
  attr_accessor :symbol, :name, :sector, :yhoo_uri, :calls_around_money, :puts_around_money
    
  def initialize(array)
    @symbol = array[0]
    @name = array[1]
    @sector = array[2]
    @yhoo_uri = BASE_URI.gsub("[symbol]", @symbol).gsub("[exp_date]",EXP_DATE.to_s)
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
        open_interest_contracts_array[0] << in_money
        start_counting_near_money = false
        next_rows = 2 # reset if iterator hits another in-the-money row on the way down the table
        open_interest_contracts_array[1] = [] # reset the near-the-money array too
      end
      
      if start_counting_near_money && next_rows >= 0
        #binding.pry
        next_rows -= 1
        #puts near_money
        open_interest_contracts_array[1] << near_money
        #puts "^ near the money"
      end
    end
    
    if open_interest_contracts_array[0].count < 3
      len = open_interest_contracts_array[0].count
      puts [open_interest_contracts_array[0][-len..-1],open_interest_contracts_array[1]].inspect
    else
      puts [open_interest_contracts_array[0][-3..-1],open_interest_contracts_array[1]].inspect
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
        open_interest_contracts_array[1] << near_money
        start_counting_in_money = false
        next_rows = 2 # reset if iterator hits another near-the-money row on the way down the table
        open_interest_contracts_array[0] = [] # reset the in-the-money array too
      end
      
      if start_counting_in_money && next_rows >= 0
        next_rows -= 1
        open_interest_contracts_array[0] << in_money
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
    
end

class StockFile
end

# ============================================================================== Program Logic

STOCKS.each do |stock|
  one_stock = Stock.new(stock)
  puts one_stock.name
  puts one_stock.symbol
  one_stock.get_puts_around_money_open_interest
end