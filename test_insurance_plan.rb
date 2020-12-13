#!/usr/bin/env ruby

require_relative 'insurance_plan'
require_relative 'claim'


ip = InsurancePlan.new(
  name: 'Plan',
  deductible: 200,
  premium: 500 * 26,
  oop_max: 3000,
)

ip.add_coverage(:primary_care_visit, coinsurance: 0.05)
ip.add_coverage(:generic_drugs, coinsurance: 0.25)
ip.add_coverage(:specialist_visit, coinsurance: 0.5)

ip.pay_year([
  Claim.new('Inhaler', :generic_drugs, 100, 75),
  Claim.new('Cold', :primary_care_visit, 1000, 800),
  Claim.new('Specialist', :specialist_visit, 40000, 35000),
]).each do |payment|
  puts payment
end


