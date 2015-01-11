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

STOCKS = CSV.read('sp500_companies.csv').sample(3)
BASE_URI = "http://finance.yahoo.com/q/op?s=[symbol]&straddle=true&date=[exp_date]"
EXP_DATE = 1421452800

class Stock
  attr_accessor :symbol, :name, :sector, :calls_around_money, :puts_around_money
    
  def initialize(array)
    @symbol = array[0]
    @name = array[1]
    @sector = array[2]
  end
  
  def is_optionable?
    yhoo_uri = BASE_URI.gsub("[symbol]", @symbol).gsub("[exp_date]",EXP_DATE.to_s)
    yhoo_options_page = Nokogiri::HTML(open(yhoo_uri)) 
    yhoo_options_page.css('.in-the-money').empty? ? false : true
  end
    
end

class StockFile
end

# ============================================================================== Program Logic

STOCKS.each do |stock|
  one_stock = Stock.new(stock)
  puts one_stock.is_optionable?
end