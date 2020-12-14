#!/usr/bin/env ruby

require_relative 'parse_tables'
require_relative 'year_simulator'

ys = YearSimulator.new

ParseTables.parse_claim_simulators('statistics.yaml').each do |cs|
  ys.add_claim_simulator(cs)
end

ParseTables.parse_plans('geha.csv').each do |ip|
  ys.add_insurance_plan(ip)
end

ys.default_callbacks

ys.validate

3000.times do
  ys.simulate
end

ys.each_insurance_plan do |plan, stats|
  mean = stats.sum / stats.count
  sd = Math.sqrt(stats.map { |x| (x - mean) ** 2 }.sum / (stats.count - 1))
  sorted_stats = stats.sort
  min_int = sorted_stats[(stats.count * 0.025).round]
  max_int = sorted_stats[(stats.count * 0.975).round]
  puts "%20s: $%8.2f ($%8.2f, $%8.2f)" % [
    plan.name, stats.sum / stats.count, min_int, max_int
  ]
end





