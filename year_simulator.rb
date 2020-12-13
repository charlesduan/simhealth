class YearSimulator

  include Distribution

  def initialize
    @claim_simulators = []
  end

  def add_claim_simulator(cs)
    @claim_simulators.push(cs)
  end

  #
  # Simulates a year of claims. It does so by running each claim simulator to
  # generate groups of claims (in the form of an array of arrays), randomizing
  # the order of the groups of claims, and flattening to produce a
  # single-dimensional array of claims.
  #
  def simulate
    return @claim_simulators.map { |cs|
      cs.simulate
    }.scramble.flatten
  end

end
