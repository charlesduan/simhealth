require_relative 'distribution'

#
# Simulates a full year of claims across multiple insurance plans. This class is
# the top-level one for managing simulations.
#
class YearSimulator

  include Distribution



  ########################################################################
  #
  # Initialization
  #
  ########################################################################

  def initialize
    @claim_simulators = []

    # Maps insurance plans to arrays of simulation results.
    @simulations = {}

    # Statistics collected for each simulated set of claims.
    @claim_stats = []
  end

  #
  # Adds a claim simulator for generating claims.
  #
  def add_claim_simulator(cs)
    @claim_simulators.push(cs)
  end

  #
  # Adds an insurance plan to this simulator.
  #
  def add_insurance_plan(ip)
    @simulations[ip] = []
  end

  def insurance_plans
    @simulations.keys
  end

  #
  # Ensures that all the insurance plans have coverage for all the possible
  # claims to be generated.
  #
  def validate
    cats = @claim_simulators.map { |cs| cs.possible_categories }.flatten.uniq
    insurance_plans.each do |ip|
      ip_cats = ip.covered_categories
      missing = cats - ip_cats
      unless missing.empty?
        raise "Insurance plan #{ip.name} is missing #{missing.join(", ")}"
      end
    end
    raise "No claims callback" unless @claims_callback.is_a?(Proc)
    raise "No payments callback" unless @payments_callback.is_a?(Proc)
  end



  ########################################################################
  #
  # Simulation
  #
  ########################################################################

  #
  # Applies a set of simulated claims to all insurance plans.
  #
  def simulate

    # Simulates a year of claims. It does so by running each claim simulator to
    # generate groups of claims (in the form of an array of arrays), randomizing
    # the order of the groups of claims, and flattening to produce a
    # single-dimensional array of claims.
    claims = @claim_simulators.map { |cs| cs.simulate }.shuffle.flatten

    # Save stats for the claims
    @claim_stats.push(@claims_callback.call(claims))

    # For each plan, simulate payments for the claims, and collect stats on the
    # payments.
    insurance_plans.each do |ip|
      payments = ip.pay_year(claims)
      @simulations[ip].push(@payments_callback.call(payments))
    end
  end



  ########################################################################
  #
  # Collecting statistics
  #
  ########################################################################

  def set_payments_callback(&block)
    @payments_callback = block
  end

  def set_claims_callback(&block)
    @claims_callback = block
  end

  def default_callbacks
    set_claims_callback do |claims|
      claims.map { |claim| claim.oop_amount }.sum
    end

    set_payments_callback do |payments|
      payments.map { |payment| payment.covered? ? 0 : payment.amount }.sum
    end
  end

  def each_insurance_plan
    @simulations.each do |plan, stats|
      yield(plan, stats)
    end
  end

end
