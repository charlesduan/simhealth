require 'set'

#
# These terms are derived from the healthcare.gov glossary,
# https://www.healthcare.gov/glossary/
#
module ClaimCategories
  LIST = Set[
    :primary_care_visit,
    :specialist_visit,
    :diagnostic_test,
    :diagnostic_test_stat,
    :imaging,
    :generic_drugs,
    :preferred_brand_drugs,
    :non_preferred_brand_drugs,
    :specialty_drugs,
    :outpatient_surgery_facility,
    :outpatient_surgery,
    :emergency_room_care,
    :emergency_medical_transportation,
    :urgent_care,
    :inpatient_hospital,
    :inpatient_surgery,
    :mental_outpatient,
    :mental_inpatient,
    :home_health_care,
    :rehabilitation_services,
    :habilitation_services,
    :skilled_nursing_care,
    :durable_medical_equipment,
    :eye_exam,
    :childrens_glasses,
    :dental_checkup,
    :dental_b,
    :dental_c,
  ]

  def valid_category?(term)
    LIST.include?(term)
  end

  def validate_category(category)
    unless valid_category?(category)
      raise TypeError, "invalid category #{category}"
    end
  end

end
