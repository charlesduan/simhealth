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

    # Stores the claims as simulated, perhaps for statistics gathering.
    @simulated_claims = []
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
  end



  ########################################################################
  #
  # Simulation
  #
  ########################################################################

  #
  # Simulates a year of claims. It does so by running each claim simulator to
  # generate groups of claims (in the form of an array of arrays), randomizing
  # the order of the groups of claims, and flattening to produce a
  # single-dimensional array of claims.
  #
  def simulate_claims
    return @claim_simulators.map { |cs|
      cs.simulate
    }.scramble.flatten
  end

  #
  # Applies a set of simulated claims to all insurance plans.
  #
  def simulate_coverage
    claims = simulate_claims
    @simulated_claims.push(claims)
    insurance_plans.each do |ip|
      payments = ip.simulate(claims)
      @simulations[ip].push(collect_stats(payments))
    end
  end


  ########################################################################
  #
  # Collecting statistics
  #
  ########################################################################

  #
  # Returns an object of statistics for this set of payments from the year.
  #
  # For now, it's just returning the out-of-pocket costs.
  #
  def collect_stats(payments)
    return payments.reject(&:covered?).map(&:amount).sum
  end

end
