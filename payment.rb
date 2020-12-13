#
# Payment represents a payment made by either the insurance plan or the
# insured person regarding a claim. Each claim may generate multiple Payment
# objects if payment comes from multiple sources (e.g., deductible, copay,
# etc.).
#
Payment = Struct.new(:claim, :from, :covered?, :amount) do
  def initialize(claim, from, covered, amount)
    raise TypeError unless from.is_a?(Symbol)
    raise TypeError unless amount > 0
    if from == :premium
      raise "Premium cannot be covered" if covered
    else
      raise TypeError unless claim.is_a?(Claim)
    end
    super(claim, from, covered, amount)
  end

  def to_s
    if from == :premium
      "You pay premium %.2f" % amount
    elsif covered?
      "Insurance pays %s [%s] in %s: %.2f" % [
        claim.category, claim.name, from, amount
      ]
    else
      "You pay %s [%s] in %s: %.2f" % [
        claim.category, claim.name, from, amount
      ]
    end
  end
end

