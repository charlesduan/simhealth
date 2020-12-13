
Claim = Struct.new(
  :name, :category, :oop_amount, :negotiated_amount
)


class ClaimSimulator

  include Distribution

  #
  # Records the conditional probability of a particular claim
  #
  ClaimProbability = Struct.new(
    :category, :prob_rng, :oop_rng, :negotiated_rng
  )

  #
  # Adds a conditional claim probability to this claim generator.
  #
  def add_claim_prob(category, prob_distrib, oop_distrib, negotiated_distrib)
    @claim_probabilities.push(ClaimProbability.new(
      category,
      parse_distribution(prob_distrib),
      parse_distribution(oop_distrib),
      parse_distribution(negotiated_distrib)
    ))
  end

  def initialize(name, distrib)
    @name = data['name']
    @rng = parse_distribution(distrib)
    @claim_probabilities = []
  end

  #
  # Generates a set of claims, based on the baseline probability for this claim
  # generator and the conditional probabilities for each resulting claim.
  def simulate
    claims = []

    # How many baseline events occur?
    @rng.call.times do

      # For each one, iterate through each possible claim generated
      @claim_probabilities.each do |cp|

        # How many of this type of claim are conditionally generated?
        cp.prob_rng.times do
          claims.push(Claim.new(
            @name,
            cp.category,
            cp.oop_rng.call,
            cp.negotiated_rng.call,
          ))
        end
      end
    end

    return claims
  end

end
