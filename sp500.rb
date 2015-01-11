require 'pry'
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



# ============================================================================== Program Logic