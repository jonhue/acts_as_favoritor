# frozen_string_literal: true

FactoryBot.define do
  factory :jon, class: 'User' do |user|
    user.name { 'Jon' }
  end

  factory :sam, class: 'User' do |user|
    user.name { 'Sam' }
  end

  factory :bob, class: 'User' do |user|
    user.name { 'Bob' }
  end
end
