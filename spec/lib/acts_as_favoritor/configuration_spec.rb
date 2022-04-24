# frozen_string_literal: true

RSpec.describe ActsAsFavoritor::Configuration do
  let(:config) { ActsAsFavoritor.configuration }

  after do
    ActsAsFavoritor.configure do |config|
      config.default_scope = :favorite
      config.cache         = false
    end
  end

  it 'has defaults set for the configuration options' do
    expect(config.default_scope).to eq :favorite
    expect(config.cache).to         be false
  end

  it 'allows configuring the gem' do
    ActsAsFavoritor.configure do |config|
      config.default_scope = :friend
      config.cache         = true
    end

    expect(config.default_scope).to eq :friend
    expect(config.cache).to         be true
  end
end
