#!/usr/bin/env ruby

require_relative 'claim_simulator'
require_relative 'year_simulator'


cs = ClaimSimulator.new('Emergency room', 'poisson 0.1')
cs.add_claim_prob(
  :emergency_room_care, 1, 'normal 4000 1000', 0.25
)
cs.add_claim_prob(
  :emergency_medical_transportation, 'coinflip 0.6', 500, 0.25
)
cs.add_claim_prob(
  :inpatient_hospital, 'coinflip 0.6', 'normal 30000 10000', 0.25
)

cats = {}
10000.times do
  cs.simulate.each do |claim|
    cats[claim.category] ||= 0
    cats[claim.category] += 1
  end
end

p cats
