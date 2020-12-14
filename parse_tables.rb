require 'csv'
require 'yaml'
require_relative 'insurance_plan'
require_relative 'claim_simulator'

class ParseTables

  def self.parse_plans(file)
    plans = []
    open(file) do |io|
      CSV.new(io, headers: true).each do |row|
        row = row.to_hash
        premium = row.delete('premium').to_i * 26
        premium -= 0 * row.delete('rewards').to_i + row.delete('hsa_value').to_i
        ip = InsurancePlan.new(
          row.delete('name'),
          premium: premium,
          deductible: row.delete('deductible').to_i,
          oop_max: row.delete('oop_max').to_i
        )
        row.each do |key, val|
          key = key.to_sym
          if val == 'uncovered'
            ip.add_coverage(key, covered: false)
          elsif val !~ /^[\d.]+$/
            raise "Invalid value #{key}: #{val}"
          elsif val.to_f < 1
            ip.add_coverage(key, coinsurance: val.to_f)
          else
            ip.add_coverage(key, copay: val.to_i)
          end
        end
        plans.push(ip)
      end
    end
    return plans
  end

  def self.parse_claim_simulators(file)
    open(file) do |io|
      return YAML.load(io.read).map do |name, cdata|
        prob = cdata.delete('probability')
        cs = ClaimSimulator.new(name, prob)
        cdata.each do |category, cpdata|
          cs.add_claim_prob(
            category.to_sym,
            cpdata['probability'],
            cpdata['oop'],
            cpdata['discount']
          )
        end
        cs
      end
    end
  end

end
