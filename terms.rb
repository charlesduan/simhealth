#
# These terms are derived from the healthcare.gov glossary,
# https://www.healthcare.gov/glossary/
#
class Terms
  LIST = Set[
    :primary_care_visit,
    :specialist_visit,
    :emergency_accidental,
    :diagnostic_test,
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
    :inpatient_hospital_facility
    :inpatient_hospital,
    :mental_outpatient,
    :mental_inpatient,
    :home_health_care,
    :rehabilitation_services,
    :habilitation_services,
    :skilled_nursing_care,
    :durable_medical_equipment,
    :childrens_eye_exam,
    :childrens_glasses,
    :childrens_dental_checkup,
  ]

  def include?(term)
    LIST.include?(term)
  end

end
