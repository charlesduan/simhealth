module Distribution
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
    'normal' => proc { |mean, sd|
      mean, sd = mean.to_f, sd.to_f
      return proc {
        theta = 2 * Math::PI * rand()
        rho = Math.sqrt(-2 * Math.log(1 - rand()))
        mean + sd * rho * Math.cos(theta)
      }
  },
    'binomial' => proc { |n, p|
      n, p = n.to_i, p.to_f
      proc {
        s = 0
        n.times { |x| s += 1 if rand() <= p }
        s
      }
  },
    'poisson' => proc { |y|
      l, k, p = Math.exp(-y.to_f), 0, 1
      proc {
        loop do
          k += 1
          p = p * rand()
          break if p <= l
        end
        k - 1
      }
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
end
