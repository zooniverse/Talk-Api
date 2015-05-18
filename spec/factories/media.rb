FactoryGirl.define do
  factory :medium do
    sequence :id
    type 'subject_location'
    association :linked, factory: :subject
    content_type 'image/jpeg'
    path_opts ['1']
    src "panoptes-uploads.zooniverse.org/1/1/#{ SecureRandom.uuid }.jpeg"
  end
end
