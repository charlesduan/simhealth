require_relative 'claim_categories'
require_relative 'claim'
require_relative 'payment'

#
# Represents an insurance plan that pays out claims as it receives them. The
# class is stateful in that it maintains a record of claims as it pays them; it
# must do so because items like the deductible and out-of-pocket maximum depend
# on the state of the previously paid claims.
#
# The main entry point to this class is the +pay_year+ method, which applies a
# full year of claims to the class.
#
class InsurancePlan

  ########################################################################
  #
  # Data Structures
  #
  ########################################################################

  #
  # Coverage represents an insurance plan's coverage parameters for a particular
  # category of loss.
  #
  Coverage = Struct.new(
    :category, :covered?, :no_deductible?, :coinsurance, :copay,
  ) do
    include ClaimCategories
    def initialize(category, covered, no_ded, coins, copay)
      raise "Invalid category #{category}" unless valid_category?(category)
      if coins.nil?
        raise TypeError unless copay.is_a?(Numeric)
        raise TypeError unless copay >= 0
      else
        raise TypeError unless copay.nil?
        raise TypeError unless coins.is_a?(Numeric)
        raise TypeError unless coins >= 0
        raise TypeError unless coins <= 1
      end
      super(category, covered, no_ded, coins, copay)
    end
  end

  def record_payment(*args)
    @payments.push(Payment.new(*args))
  end

  ########################################################################
  #
  # Main Class
  #
  ########################################################################

  attr_reader :name, :payments

  def initialize(name:, premium:, deductible:, oop_max:)
    @name, @premium, @deductible, @oop_max = name, premium, deductible, oop_max
    @coverages = {}
  end

  def add_coverage(
    category, coinsurance: nil, copay: nil,
    covered: true, no_deductible: false
  )
    coverage = Coverage.new(
      category, covered, no_deductible, coinsurance, copay
    )
    raise "Duplicate coverage for #{category}" if @coverages[category]
    @coverages[category] = coverage
  end

  def covered_categories
    return @coverages.keys
  end

  ########################################################################
  #
  # PAYING A CLAIM
  #
  ########################################################################

  #
  # Pays a single claim.
  #
  def pay(claim)
    coverage = @coverages[claim.category]
    unless coverage
      raise "Coverage for #{claim.category} not defined for #{name}"
    end

    if !coverage.covered?
      record_payment(claim, :uncovered, false, claim.oop_amount)
      return
    end
    to_pay = claim.negotiated_amount

    to_pay = pay_from_deductible(to_pay, claim, coverage)
    to_pay = pay_coverage(to_pay, claim, coverage)
    pay_oop(to_pay, claim)
  end

  # Pays out from the deductible. Returns the amount left to pay, and adds a
  # record to the payment_record.
  def pay_from_deductible(to_pay, claim, coverage)
    return if coverage.no_deductible? || to_pay == 0

    ded_used = @payments.select { |rec|
      rec.from == :deductible && !rec.covered?
    }.map(&:amount).sum
    return to_pay unless ded_used < @deductible

    ded_left = @deductible - ded_used
    if to_pay > ded_left
      record_payment(claim, :deductible, false, ded_left)
      to_pay -= ded_left
      return to_pay
    else
      record_payment(claim, :deductible, false, to_pay)
      return 0
    end
  end

  def pay_coverage(to_pay, claim, coverage)
    return 0 if to_pay == 0
    if coverage.coinsurance
      coinsurance = (to_pay * coverage.coinsurance).round
      record_payment(claim, :coinsurance_covered, true, to_pay - coinsurance)
      return coinsurance

    elsif coverage.copay
      if to_pay > coverage.copay
        to_pay -= coverage.copay
        record_payment(claim, :copay_covered, true, to_pay)
        return coverage.copay
      else
        record_payment(claim, :copay_covered, true, to_pay)
        return 0
      end

    end
  end

  #
  # Pays the balance of the bill out of pocket or from insurance if the
  # out-of-pocket maximum has been met. This method returns nothing; all
  # payments should be accounted for.
  #
  def pay_oop(to_pay, claim)
    return if to_pay == 0
    paid_oop = @payments.select { |rec|
      !rec.covered? && rec.from != :premium && rec.from != :balance_billing
    }.map(&:amount).sum
    oop_left = @oop_max - paid_oop
    if oop_left <= 0
      # @oop_max was reached. Everything is covered.
      record_payment(claim, :oop_max, true, to_pay)
    elsif oop_left >= to_pay
      # @oop_max will not be reached if this claim is paid out of pocket.
      record_payment(claim, :oop, false, to_pay)
    else
      # Some of the payment will be out of pocket, and some will be covered due
      # to the max.
      record_payment(claim, :oop, false, oop_left)
      record_payment(claim, :oop_max, true, @oop_max - oop_left)
    end
  end

  ########################################################################
  #
  # PAYING A YEAR OF CLAIMS
  #
  ########################################################################

  #
  # Given an array of claims for a full year, pays each one. This method resets
  # the state of the class (starting the year with a blank slate of no claims
  # paid), and accumulates the payments made, returning them as an array of
  # Payment objects.
  #
  # This method also adds a payment for the yearly premium.
  #
  def pay_year(claims)
    @payments = [ Payment.new(nil, :premium, false, @premium) ]
    claims.each do |claim|
      pay(claim)
    end
    return @payments
  end
end

