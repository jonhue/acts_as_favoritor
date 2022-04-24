# frozen_string_literal: true

RSpec.describe ActsAsFavoritor::FavoritorLib do
  describe 'build_result_for_scopes' do
    it 'returns nil when scopes is empty' do
      expect(Dummy.build_result_for_scopes([])).to be_nil
    end

    it 'returns result of the block when a single scope is given' do
      expect(Dummy.build_result_for_scopes(:favorite) do |scope|
        scope.to_s.upcase
      end).to eq 'FAVORITE'
    end

    it 'returns a hash with scopes as keys ' \
       'and the results of the block as values' do
      expect(Dummy.build_result_for_scopes([:favorite, :friend]) do |scope|
        scope.to_s.upcase
      end).to eq(favorite: 'FAVORITE', friend: 'FRIEND')
    end
  end
end

class Dummy
  extend ActsAsFavoritor::FavoritorLib
end
