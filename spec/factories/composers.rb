# frozen_string_literal: true

FactoryBot.define do
  factory :beethoven, class: 'Composer' do |composer|
    composer.name { 'Beethoven' }
  end

  factory :rossini, class: 'Composer' do |composer|
    composer.name { 'Rossini' }
  end
end
