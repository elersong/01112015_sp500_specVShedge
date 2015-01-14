#01112015 S&P Hedging vs Speculation#

Testing a hypothesis by NB concerning current market valuation and speculated
directionality in the near future. Collect number of open interest contracts
for strike prices in and near-the-money.

The "daily_details_around_the_money.csv" file contains 12 data points for each
ticket symbol per day, entered on 2 rows. All odd numbered rows hold information
about call options. All even numbered rows hold information about put options.

Each individual row will hold no more than 6 data points. Three of them represent
the open interest contracts for that strike price in-the-money and the other three
represent the same thing near-the-money. When there are not sufficient contracts
to support data collection, the row will hold fewer than the 3 points of each type.

type "ruby sp500.rb" in console to run script