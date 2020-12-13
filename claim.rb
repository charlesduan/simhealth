#
# A claim for insurance coverage.
#
Claim = Struct.new(
  :name, :category, :oop_amount, :negotiated_amount
) do
  include ClaimCategories
  def initialize(name, category, oop, negotiated)
    validate_category(category)
    raise TypeError unless oop.is_a?(Numeric)
    raise TypeError unless negotiated.is_a?(Numeric)
    super(name, category, oop, negotiated)
  end

  def to_s
    "Claim for %s [%s]: $%0.2f/$%.02f" % [
      category, name, oop_amount, negotiated_amount
    ]
  end
end



