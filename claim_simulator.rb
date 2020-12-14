require_relative 'claim_categories'
require_relative 'distribution'
require_relative 'claim'

#
# Maintains metadata on a particular class of claims that may be generated
# during a year, and produces a set of claims for that class. A ClaimSimulator
# should generally relate to a particular event that can produce one or more
# claims. For example, the event "breaking a leg" may be a ClaimSimulator, which
# could result in several claims such as an outpatient visit or an emergency
# room visit.
#
# The model for the ClaimSimulator is that there is a conditional probability
# that the event occurs, and if it does, a series of independent claims may
# ensue, each with its own conditional probability and probabilistic charges.
# Currently there is no facility for the claims to be dependent on each other;
# each claim arises independently assuming that the event occurs. (This may be
# improved in the future.)
#
class ClaimSimulator

  include Distribution

  #
  # Records the conditional probability of a particular claim
  #
  ClaimProbability = Struct.new(
    :category, :prob_rng, :oop_rng, :discount_rng
  ) do
    include ClaimCategories
    def initialize(category, prng, orng, drng)
      validate_category(category)
      [ prng, orng, drng ].each do |rng|
        raise TypeError unless rng.is_a?(Proc)
      end
      super(category, prng, orng, drng)
    end
  end

  #
  # Adds a conditional claim probability to this claim generator.
  #
  def add_claim_prob(category, prob_distrib, oop_distrib, discount_distrib)
    @claim_probabilities.push(ClaimProbability.new(
      category,
      parse_distribution(prob_distrib),
      parse_distribution(oop_distrib),
      parse_distribution(discount_distrib)
    ))
  end

  def initialize(name, distrib)
    @name = name
    @rng = parse_distribution(distrib)
    @claim_probabilities = []
  end

  attr_reader :name

  def to_s
    s = "Claim simulator #{@name}:\n"
    @claim_probabilities.each do |cp|
      s += "  #{cp.category}\n"
    end
    return s
  end

  #
  # Returns an array of possible categories that this ClaimSimulator could
  # produce.
  #
  def possible_categories
    @claim_probabilities.map { |cp| cp.category }
  end

  #
  # Generates a set of claims, based on the baseline probability for this claim
  # generator and the conditional probabilities for each resulting claim.
  #
  def simulate
    claims = []

    # How many baseline events occur?
    @rng.call.times do

      # For each one, iterate through each possible claim generated
      @claim_probabilities.each do |cp|

        # How many of this type of claim are conditionally generated?
        cp.prob_rng.call.times do
          oop_amount = cp.oop_rng.call
          discount = cp.discount_rng.call
          raise "Invalid discount #{discount}" if discount < 0 || discount > 1
          negotiated_amount = oop_amount * (1 - cp.discount_rng.call)
          claims.push(Claim.new(
            @name,
            cp.category,
            oop_amount,
            oop_amount * (1 - cp.discount_rng.call),
          ))
        end
      end
    end

    return claims
  end

end
