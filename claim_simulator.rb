require 'distribution'


Claim = Struct.new(
  :category, :oop_amount, :negotiated_amount
)


class ClaimSimulator

  #
  # Each distribution is a proc that takes a number of arguments defining the
  # distribution and returns a proc that generates a random output for the
  # distribution.
  #
  DISTRIBUTIONS = {
    'fixed' => proc { |count|
      count = count.to_i
      proc { count }
  },
    'uniform' => proc { |min, max|
      min = min.to_i
      range = max.to_i - min
      proc { rand(range) + min }
  },
    'lognormal' => proc { |mean, sd|
      Distribution::Lognormal.rng(mean.to_f, sd.to_f)
  },
    'binomial' => proc { |n, p|
      n, p = n.to_i, p.to_f
      proc { (1..n).map { |x| rand() <= p ? 1 : 0 }.sum }
  },
  }

  #
  # Parses a distribution specification and returns the generator proc.
  #
  def parse_distribution(text)
    words = text.split(/\s+/)
    first_word = words.shift
    if words.length == 0 && first_word =~ /^\d+/
      return DISTRIBUTIONS['fixed'].call(first_word)
    else
      distrib = DISTRIBUTIONS[first_word]
      raise "Unknown distribution #{first_word}" unless distrib
      return distrib.call(*words)
    end
  end

  #
  # Records the conditional probability of a particular claim
  ClaimProbability = Struct.new(
    :category, :oop_distrib, :negotiated_distrib
  )

  def add_claim
  def initialize(name, distrib)
    @name = data['name']
    @rng = parse_distribution(distrib)
  end




end
