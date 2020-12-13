module Distribution
  #
  # Each distribution is a proc that takes a number of arguments defining the
  # distribution and returns a proc that generates a random output for the
  # distribution.
  #
  DISTRIBUTIONS = {
    'fixed' => proc { |count|
      if count =~ /^\d+\.\d+$/
        count = count.to_f
      elsif count =~ /^\d+$/
        count = count.to_i
      else
        raise "Invalid fixed count #{count}"
      end
      proc { count }
  },
    'uniform' => proc { |min, max|
      min = min.to_i
      range = max.to_i - min
      raise "Invalid uniform distribution" unless range > 1
      proc { rand(range) + min }
  },
    'coinflip' => proc { |p|
      p = p.to_f
      raise "Invalid coinflip distribution" unless p > 0 && p < 1
      proc { rand() <= p ? 1 : 0 }
  },
    'normal' => proc { |mean, sd|
      mean, sd = mean.to_f, sd.to_f
      raise "Invalid normal distribution" unless sd > 0
      proc {
        theta = 2 * Math::PI * rand()
        rho = Math.sqrt(-2 * Math.log(1 - rand()))
        mean + sd * rho * Math.cos(theta)
      }
  },
    'binomial' => proc { |n, p|
      n, p = n.to_i, p.to_f
      raise "Invalid binomial distribution" unless n >= 1 && p > 0 && p < 1
      proc {
        s = 0
        n.times { |x| s += 1 if rand() <= p }
        s
      }
  },
    'poisson' => proc { |y|
      y = y.to_f
      raise "Invalid Poisson distribution" unless y > 0
      l = Math.exp(-y)
      proc {
        k, p = 0, 1
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
    words = text.to_s.split(/\s+/)
    first_word = words.shift
    if words.length == 0 && first_word =~ /^[\d.]+$/
      return DISTRIBUTIONS['fixed'].call(first_word)
    else
      distrib = DISTRIBUTIONS[first_word]
      raise "Unknown distribution #{first_word}" unless distrib
      return distrib.call(*words)
    end
  end
end
