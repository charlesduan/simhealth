#!/usr/bin/env ruby

require_relative 'year_simulator'
require_relative 'claim_simulator'
require_relative 'insurance_plan'

ys = YearSimulator.new

#
# Claims
#

cs = ClaimSimulator.new('Claim1', 'poisson 0.3')
cs.add_claim_prob(
  :emergency_room_care, 1, 'lognormal 4000 1000', 0
)
cs.add_claim_prob(
  :emergency_medical_transportation, 'coinflip 0.6', 500, 0
)
cs.add_claim_prob(
  :inpatient_hospital, 'coinflip 0.6', 'lognormal 30000 10000', 0
)
ys.add_claim_simulator(cs)

cs = ClaimSimulator.new('Claim2', 'poisson 1.5')
cs.add_claim_prob(:primary_care_visit, 1, 'lognormal 300 100', 0)
ys.add_claim_simulator(cs)

#
# Insurance plans
#

ip = InsurancePlan.new(
  'Plan1', premium: 10000, deductible: 100, oop_max: 3000
)
ip.add_coverage(:primary_care_visit, copay: 50)
ip.add_coverage(:emergency_room_care, copay: 300)
ip.add_coverage(:emergency_medical_transportation, copay: 100)
ip.add_coverage(:inpatient_hospital, copay: 500)
ys.add_insurance_plan(ip)

ip = InsurancePlan.new(
  'Plan2', premium: 7000, deductible: 2000, oop_max: 8000
)
ip.add_coverage(:primary_care_visit, coinsurance: 0.2)
ip.add_coverage(:emergency_room_care, coinsurance: 0.2)
ip.add_coverage(:emergency_medical_transportation, coinsurance: 0.2)
ip.add_coverage(:inpatient_hospital, coinsurance: 0.2)
ys.add_insurance_plan(ip)

ys.default_callbacks

ys.validate

100000.times do
  ys.simulate
end

ys.each_insurance_plan do |plan, stats|
  puts "%s: mean cost $%.2f" % [ plan.name, stats.sum / stats.count ]
  puts "%s:  max cost $%.2f" % [ plan.name, stats.max ]
  puts "%s:  min cost $%.2f" % [ plan.name, stats.min ]
end


