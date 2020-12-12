require 'terms'
require 'claim'

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
    :category, :no_deductible, :coinsurance, :copay,
  )
  def validate_coverage(coverage)
    raise TypeError unless coverage.is_a?(Coverage)
    raise TypeError unless Terms.include?(coverage.category)
    if coverage.coinsurance.nil?
      raise TypeError unless coverage.copay.is_a?(Numeric)
      raise DomainError unless coverage.copay >= 0
    else
      raise TypeError unless coverage.copay.nil?
      raise TypeError unless coverage.coinsurance.is_a?(Numeric)
      raise DomainError unless coverage.coinsurance >= 0
      raise DomainError unless coverage.coinsurance <= 1
    end
  end

  #
  # Payment represents a payment made by either the insurance plan or the
  # insured person regarding a claim. Each claim may generate multiple Payment
  # objects if payment comes from multiple sources (e.g., deductible, copay,
  # etc.).
  #
  Payment = Struct.new(:claim, :from, :covered, :amount)

  def validate_payment(payment)
    raise TypeError unless payment.is_a?(Payment)
    raise TypeError unless payment.claim.is_a?(Claim)
    raise TypeError unless payment.from.is_a?(Symbol)
    raise DomainError unless payment.amount > 0
  end

  def record_payment(*args)
    @payments.push(Payment.new(*args))
    validate_payment(@payments.last)
  end

  ########################################################################
  #
  # Main Class
  #
  ########################################################################

  attr_reader :name

  def initialize(input)
    @name = input['name']
    @deductible = input['deductible']
    @oop_max = input['oop_max']
    @payments = []
    @coverages = {}
    input['coverages'].each do |cat, cov|
      cat = cat.to_sym
      coverage = Coverage.new(
        cat, !!cov['no_deductible'], cov['coinsurance'], cov['copay']
      )
      validate_coverage(coverage)
      @coverages[cat] = cov
    end
  end

  def pay(claim)
    to_pay = claim.amount
    coverage = @coverages[claim.category]
    unless coverage
      raise "Coverage for #{claim.category} not defined for #{name}"
    end

    to_pay = pay_from_deductible(to_pay, claim, coverage)
    to_pay = pay_coverage(to_pay, claim, coverage)
    pay_oop(to_pay, claim)
  end

  # Pays out from the deductible. Returns the amount left to pay, and adds a
  # record to the payment_record.
  def pay_from_deductible(to_pay, claim, coverage)
    return if coverage.no_deductible || to_pay == 0

    ded_used = @payments.select { |rec|
      rec.from == :deductible && !rec.covered
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
    paid_oop = @payments.select { |rec|
      !rec.covered && rec.from != :premium && rec.from != :balance_billing
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

end

