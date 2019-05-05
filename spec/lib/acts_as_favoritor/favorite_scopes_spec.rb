# frozen_string_literal: true

require_relative '../../rails_helper'

RSpec.describe ActsAsFavoritor::FavoriteScopes do
  let(:sam) { create :sam }
  let(:jon) { create :jon }
  let(:beethoven) { create :beethoven }

  before do
    Favorite.delete_all

    sam.favorite(jon)
    sam.favorite(beethoven)
    jon.favorite(sam)
    beethoven.favorite(jon)
  end

  describe 'for_favoritor' do
    it 'returns favorites of the given favoritor' do
      expect(Favorite.for_favoritor(sam))
        .to eq [Favorite.find_by(favoritor: sam, favoritable: jon),
                Favorite.find_by(favoritor: sam, favoritable: beethoven)]
    end
  end

  describe 'for_favoritable' do
    it 'returns favorites with the given favoritable' do
      expect(Favorite.for_favoritable(sam))
        .to eq [Favorite.find_by(favoritor: jon, favoritable: sam)]
    end
  end

  describe 'for_favoritor_type' do
    it 'returns favorites of favoritors with the given type' do
      expect(Favorite.for_favoritor_type('User'))
        .to eq [Favorite.find_by(favoritor: sam, favoritable: jon),
                Favorite.find_by(favoritor: sam, favoritable: beethoven),
                Favorite.find_by(favoritor: jon, favoritable: sam)]
    end
  end

  describe 'for_favoritable_type' do
    it 'returns favorites with favoritables of the given type' do
      expect(Favorite.for_favoritable_type('User'))
        .to eq [Favorite.find_by(favoritor: jon, favoritable: sam),
                Favorite.find_by(favoritor: sam, favoritable: jon),
                Favorite.find_by(favoritor: beethoven, favoritable: jon)]
    end
  end

  context 'with block/unblock' do
    before { jon.block(beethoven) }

    describe 'unblocked' do
      it 'returns unblocked favorites' do
        expect(Favorite.unblocked)
          .to eq [Favorite.find_by(favoritor: sam, favoritable: jon),
                  Favorite.find_by(favoritor: sam, favoritable: beethoven),
                  Favorite.find_by(favoritor: jon, favoritable: sam)]
      end
    end

    describe 'blocked' do
      it 'returns blocked favorites' do
        expect(Favorite.blocked)
          .to eq [Favorite.find_by(favoritor: beethoven, favoritable: jon)]
      end
    end
  end

  context 'with magic methods' do
    it 'responds to magic methods' do
      expect(Favorite).to respond_to(:favorite_list)
    end

    it 'still raises a NoMethodError' do
      expect { Favorite.foobar }.to raise_error(NoMethodError)
    end

    it '*_list returns favorites with the given scope' do
      jon.favorite(sam, scopes: [:friend])

      expect(Favorite.friend_list)
        .to eq [Favorite.find_by(favoritor: jon, favoritable: sam,
                                 scope: :friend)]
    end
  end
end
