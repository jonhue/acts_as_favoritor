# frozen_string_literal: true

FactoryBot.define do
  factory :beethoven, class: Composer do |composer|
    composer.name { 'Beethoven' }
  end

  factory :rossini, class: Composer do |composer|
    composer.name { 'Rossini' }
  end

  # factory :green_day, class: Band::Punk do |b|
  #   b.name { 'Green Day' }
  # end
  #
  # factory :blink_182, class: Band::Punk::PopPunk do |b|
  #   b.name { 'Blink 182' }
  # end
end
