require_relative 'insurance_plan'
require 'csv'

class ParseTables

  def self.parse_plans(file)
    plans = []
    open(file) do |io|
      CSV.new(io, headers: true).each do |row|
        row = row.to_hash
        premium = row.delete('premium') * 26
        premium -= row.delete('rewards') + row.delete('hsa_value')
        ip = InsurancePlan.new(
          row['name'],
          premium: premium,
          deductible: row.delete('deductible'),
          oop_max: row.delete('oop_max')
        )
        row.each do |key, val|
          key = key.to_sym
          if val == 'uncovered'
            ip.add_coverage(key, covered: false)
          elsif val !~ /^[\d.]+]$/
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

end
