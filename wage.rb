#!/usr/bin/env ruby
# File: wage.rb

USAGE = <<ENDUSAGE
Usage:
  wage [-h] annual_income
ENDUSAGE

HELP = <<ENDHELP
  -h --help       Show this message.

annual_income is the annual pre-tax income.

Caveats:
Only the United Kingdom is supported.
Only the year 2016 is supported.
Only tax code 1060L is supported.
Married Couple's Allowance is not supported.
Tax on dividends is not supported.
Capital-gains tax is not supported.
Only Class 1 National Insurance is supported, with limitations.
ENDHELP


class WageError < RuntimeError
end

class Tax

  def initialize(tax)
    @bands = []
    @thresholds = []
    @rates = []
    tax.each do | t |
      @bands << t[0]
      @thresholds << t[1]
      @rates << t[2]
    end
  end

  def get_band_id(income)
    @thresholds.each_with_index { |th, i| return i if income <= th }
    raise WageError.new("income is out of range")
  end

  def get_band(income)
    return @bands[get_band_id income]
  end

  def get_threshold_lo(income)
    return @thresholds[[0, get_band_id(income) - 1].max]
  end

  def get_rate(income)
    return @rates[get_band_id income]
  end

end

MAX_INCOME = 1000000000000000000

income_tax_data = [
  [:basic, 31785, 0.20],
  [:higher, 150000, 0.40],
  [:additional, MAX_INCOME, 0.45]
]

national_insurance_data = [
  [:lower_earnings_limit, 486, 0.0],
  [:primary_threshold, 672, 0.12],
  [:upper_accrual_point, 3337, 0.12],
  [:upper_earnings_limit, 3532, 0.12],
  [:above_upper_earnings_limit, MAX_INCOME, 0.02]
]

income_tax_table = Tax.new income_tax_data
national_insurance_tax_table = Tax.new national_insurance_data

if __FILE__ == $0
  ARGS = {}
  UNFLAGGED_ARGS = [ :annual_income ]
  next_arg = UNFLAGGED_ARGS.first
  ARGV.each do |arg|
    case arg
      when '-h', '--help'           then ARGS[:help] = true
      when '-v', '--verbose'        then ARGS[:verbose] = true
      else
        if next_arg
          ARGS[next_arg] = arg
          UNFLAGGED_ARGS.delete next_arg
        end
        next_arg = UNFLAGGED_ARGS.first
      end
  end
  if ARGS[:help] or not UNFLAGGED_ARGS.empty?
    puts USAGE
    puts HELP if ARGS[:help]
    exit
  end

  country = :united_kingdom
  year = 2016
  # Tax free income
  personal_allowance = 10600
  personal_allowance_limit = 100000
  # Rate of deduction from personal allowance for incomes above the limit
  personal_allowance_penalty = 2

  married_couples_allowance = 0
  blind_persons_allowance = 2290

  income = ARGS[:annual_income].delete(",").to_i
  monthly_income = income / 12.0

  allowance = personal_allowance - \
    [income - personal_allowance_limit, 0].max * personal_allowance_penalty
  taxable_income = [income - allowance, 0].max
  income_tax = taxable_income * income_tax_table.get_rate(taxable_income)

  ni_taxable_monthly_income = monthly_income - \
    national_insurance_tax_table.get_threshold_lo(monthly_income)
  ni_tax = ni_taxable_monthly_income * 12.0 * \
    national_insurance_tax_table.get_rate(monthly_income)

  net_tax = income_tax + ni_tax
  net_income = income - net_tax
  net_monthly_income = net_income / 12.0

  puts "annual income: #{income}" if ARGS[:verbose]
  puts "monthly income #{monthly_income}" if ARGS[:verbose]
  puts "taxable income: #{taxable_income}" if ARGS[:verbose]
  puts "NI taxable income #{ni_taxable_monthly_income}" if ARGS[:verbose]
  puts "income tax: #{income_tax}" if ARGS[:verbose]
  puts "National Insurance tax: #{ni_tax}" if ARGS[:verbose]
  puts "net annual income: #{net_income}"
end
