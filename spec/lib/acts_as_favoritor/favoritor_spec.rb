# frozen_string_literal: true

require_relative '../../rails_helper'

RSpec.describe ActsAsFavoritor::Favoritor do
  let(:sam) { create :sam }
  let(:jon) { create :jon }
  let(:beethoven) { create :beethoven }

  context 'without scopes' do
    before do
      sam.favorite(jon)
      sam.favorite(beethoven)
      jon.favorite(sam)
      beethoven.favorite(jon)
    end

    describe 'favorites' do
      it 'returns all favorite records of the given instance' do
        expect(sam.favorites)
          .to eq [Favorite.find_by(favoritor: sam, favoritable: jon),
                  Favorite.find_by(favoritor: sam, favoritable: beethoven)]
      end
    end

    describe 'favorite' do
      # rubocop:disable RSpec/NestedGroups
      context 'when the given instance is the current object' do
        it 'returns nil' do
          expect(jon.favorite(jon)).to be_nil
        end

        it 'does not create a favorite record' do
          expect { jon.favorite(jon) }.to change { jon.favorites.size }.by(0)
        end
      end

      context 'when the given instance is not the current object' do
        it 'returns the new favorite record' do
          expect(beethoven.favorite(sam))
            .to eq Favorite.find_by(favoritor: beethoven, favoritable: sam)
        end

        it 'creates a favorite record' do
          expect { beethoven.favorite(sam) }
            .to change { beethoven.favorites.size }.by(1)
        end
      end

      context 'when caching is enabled' do
        it 'updates the favoritor cache'

        it 'updates the favoritable cache'

        it 'does not update the cache when there was an early return'
      end
      # rubocop:enable RSpec/NestedGroups
    end

    describe 'unfavorite' do
      # rubocop:disable RSpec/NestedGroups
      context 'when the given instance has not been favorited' do
        it 'returns nil' do
          expect(beethoven.unfavorite(sam)).to be_nil
        end

        it 'does not delete a favorite record' do
          expect { beethoven.unfavorite(sam) }
            .to change { beethoven.favorites.size }.by(0)
        end
      end

      context 'when the given instance has been favorited' do
        it 'returns the deleted favorite record' do
          favorite_record =
            Favorite.find_by(favoritor: beethoven, favoritable: jon)

          expect(beethoven.unfavorite(jon))
            .to eq favorite_record
        end

        it 'deletes a favorite record' do
          expect { beethoven.unfavorite(jon) }
            .to change { beethoven.favorites.size }.by(-1)
        end
      end

      context 'when caching is enabled' do
        it 'updates the favoritor cache'

        it 'updates the favoritable cache'

        it 'does not update the cache when there was an early return'
      end
      # rubocop:enable RSpec/NestedGroups
    end

    describe 'favorited?' do
      it 'returns true if the instance favorited the given record' do
        expect(beethoven.favorited?(jon)).to be true
      end

      it 'returns false if the instance did not favorite the given record' do
        expect(jon.favorited?(beethoven)).to be false
      end
    end

    describe 'all_favorites' do
      before { beethoven.block(sam) }

      it 'returns all unblocked favorite records of the given instance' do
        expect(sam.all_favorites).not_to be_a Array

        expect(sam.all_favorites)
          .to eq [Favorite.find_by(favoritor: sam, favoritable: jon)]
      end
    end

    describe 'all_favorited' do
      before { beethoven.block(sam) }

      it 'returns all unblocked favorites of the given instance' do
        expect(sam.all_favorited).to eq [jon]
      end
    end

    describe 'favorites_by_type' do
      it 'all unblocked favorite records of the current instance where ' \
         'the favoritable is of the given type' do
        expect(sam.favorites_by_type('User')).not_to be_a Array

        expect(sam.favorites_by_type('User'))
          .to eq [Favorite.find_by(favoritor: sam, favoritable: jon)]
        expect(sam.favorites_by_type('Composer'))
          .to eq [Favorite.find_by(favoritor: sam, favoritable: beethoven)]
      end
    end

    describe 'favorited_by_type' do
      it 'all unblocked favorites of the current instance where ' \
         'the favoritable is of the given type' do
        expect(sam.favorited_by_type('User')).not_to be_a Array

        expect(sam.favorited_by_type('User')).to eq [jon]
        expect(sam.favorited_by_type('Composer')).to eq [beethoven]
      end
    end

    describe 'blocked_by?' do
      it 'returns true if the given instance blocked this object' do
        jon.block(beethoven)

        expect(beethoven.blocked_by?(jon)).to be true
      end

      it 'returns false if the given instance did not block this object' do
        expect(jon.blocked_by?(beethoven)).to be false
      end
    end

    describe 'blocked_by' do
      before { jon.block(beethoven) }

      it 'returns blocked favoritors' do
        expect(beethoven.blocked_by).to eq [jon]
      end
    end

    context 'with magic methods' do
      it 'responds to magic methods' do
        expect(jon).to respond_to(:favorited_users)
      end

      it 'still raises a NoMethodError' do
        expect { jon.foobar }.to raise_error(NoMethodError)
      end

      it 'favorited_* returns favorites of the given type' do
        expect(jon.favorited_users).to eq [sam]
      end
    end
  end

  context 'with scopes' do
    before do
      sam.favorite(jon, scopes: [:friend])
      sam.favorite(beethoven, scopes: [:favorite, :friend])
      jon.favorite(sam, scopes: [:friend])
      beethoven.favorite(jon, scopes: [:favorite])
    end

    describe 'favorite' do
      it 'creates a favorite record with the given scopes' do
        expect { beethoven.favorite(jon, scope: :friend) }
          .to  change { beethoven.all_favorites(scope: :friend).size }.by(1)
          .and change { beethoven.all_favorites(scope: :favorite).size }
            .by(0)
      end
    end

    describe 'unfavorite' do
      it 'deletes favorite records with the given scopes' do
        expect { sam.unfavorite(beethoven, scope: :friend) }
          .to  change { sam.all_favorites(scope: :friend).size }.by(-1)
          .and change { sam.all_favorites(scope: :favorite).size }.by(0)
      end
    end

    describe 'favorited?' do
      it 'returns true if the instance favorited the given record' do
        expect(beethoven.favorited?(jon, scope: :favorite)).to be true
      end

      it 'returns false if the instance did not favorite the given record' do
        expect(beethoven.favorited?(jon, scope: :friend)).to be false
      end
    end

    describe 'all_favorites' do
      it 'returns all unblocked favorite records of the given instance' do
        expect(sam.all_favorites(scope: :favorite))
          .to eq [Favorite.find_by(favoritor: sam, favoritable: beethoven)]
      end
    end

    describe 'all_favorited' do
      it 'returns all unblocked favorites of the given instance' do
        expect(sam.all_favorited(scope: :favorite)).to eq [beethoven]
      end
    end

    describe 'favorites_by_type' do
      it 'all unblocked favorite records of the current instance ' \
         'where the favoritable is of the given type' do
        expect(sam.favorites_by_type('User', scope: :favorite)).to eq []
        expect(sam.favorites_by_type('Composer', scopes: [:favorite, :friend]))
          .to eq(
            favorite: [Favorite.find_by(favoritor: sam, favoritable: beethoven,
                                        scope: :favorite)],
            friend: [Favorite.find_by(favoritor: sam, favoritable: beethoven,
                                      scope: :friend)]
          )
      end
    end

    describe 'favorited_by_type' do
      it 'all unblocked favorites of the current instance ' \
         'where the favoritable is of the given type' do
        expect(sam.favorited_by_type('User', scope: :favorite)).to eq []
        expect(sam.favorited_by_type('Composer', scopes: [:favorite, :friend]))
          .to eq favorite: [beethoven], friend: [beethoven]
      end
    end

    describe 'blocked_by?' do
      it 'returns true if the given instance blocked this object' do
        jon.block(beethoven, scope: :favorite)

        expect(beethoven.blocked_by?(jon, scope: :favorite)).to be true
      end

      it 'returns false if the given instance did not block this object' do
        jon.block(beethoven, scope: :friend)

        expect(beethoven.blocked_by?(jon, scope: :favorite)).to be false
      end
    end

    describe 'blocked_by' do
      before do
        jon.block(beethoven, scope: :friend)
        jon.block(sam, scope: :favorite)
      end

      it 'returns blocked favoritors' do
        expect(beethoven.blocked_by(scope: :friend)).to eq [jon]
      end
    end
  end
end
