# frozen_string_literal: true

require_relative '../rails_helper'

RSpec.describe 'acts_as_favoritor' do
  let(:sam)       { create :sam }
  let(:jon)       { create :jon }
  let(:beethoven) { create :beethoven }
  let(:rossini)   { create :rossini }

  context 'without scopes' do
    before do
      jon.favorite(sam)
      sam.favorite(jon)
      sam.favorite(beethoven)
      sam.favorite(rossini)
    end

    it 'responds to instance methods' do
      expect(sam).to respond_to(:favorite)
      expect(sam).to respond_to(:unfavorite)
      expect(sam).to respond_to(:favorited?)
      expect(sam).to respond_to(:all_favorites)
      expect(sam).to respond_to(:all_favorited)
      expect(sam).to respond_to(:favorites_by_type)
      expect(sam).to respond_to(:favorited_by_type)
      expect(sam).to respond_to(:blocked_by?)
      expect(sam).to respond_to(:blocked_by)
    end

    describe 'favorite' do
      it 'allows favoriting objects' do
        expect { jon.favorite(beethoven) }
          .to  change(Favorite, :count).by(1)
          .and change { jon.all_favorites.size }.by(1)
          .and change { jon.favorited?(beethoven) }.from(false).to(true)
      end

      it 'cannot favorite itself' do
        expect { jon.favorite(jon) }.to change(Favorite, :count).by(0)
          .and change { jon.all_favorites.size }.by(0)
        expect(jon.favorited?(jon)).to be false
      end
    end

    describe 'unfavorite' do
      it 'allows removing favorites' do
        expect { jon.unfavorite(sam) }
          .to  change(Favorite, :count).by(-1)
          .and change { jon.all_favorites.size }.by(-1)
          .and change { jon.favorited?(sam) }.from(true).to(false)
      end
    end

    describe 'favorites_by_type' do
      it 'only returns favorites of a given type' do
        expect(sam.favorites_by_type('User'))
          .to eq [Favorite.find_by(favoritor: sam, favoritable: jon)]
        expect(sam.favorites_by_type('Composer'))
          .to eq [Favorite.find_by(favoritor: sam, favoritable: beethoven),
                  Favorite.find_by(favoritor: sam, favoritable: rossini)]
      end
    end

    describe 'all_favorites' do
      it 'returns all favorites' do
        expect(jon.all_favorites)
          .to eq [Favorite.find_by(favoritor: jon, favoritable: sam)]
        expect(sam.all_favorites)
          .to eq [Favorite.find_by(favoritor: sam, favoritable: jon),
                  Favorite.find_by(favoritor: sam, favoritable: beethoven),
                  Favorite.find_by(favoritor: sam, favoritable: rossini)]
      end
    end

    describe 'favorited_by_type' do
      it 'only returns favorited objects of a given type' do
        expect(sam.favorited_by_type('User')).to     eq [jon]
        expect(sam.favorited_by_type('Composer')).to eq [beethoven, rossini]
      end
    end

    describe 'all_favorited' do
      it 'returns favorited objects' do
        expect(jon.all_favorited).to eq [sam]
        expect(sam.all_favorited).to eq [jon, beethoven, rossini]
      end
    end

    context 'with magic methods' do
      it 'responds to magic methods' do
        expect(sam).to respond_to(:favorited_users)
        expect(sam).to respond_to(:favorited_users_count)
      end

      it 'still raises a NoMethodError' do
        expect { sam.foobar }.to raise_error(NoMethodError)
      end

      it 'favorited_* returns favorited_by_type' do
        expect(sam.favorited_users).to     eq [jon]
        expect(sam.favorited_composers).to eq [beethoven, rossini]
      end
    end
  end

  context 'with scopes' do
    before do
      jon.favorite(sam, scopes: [:favorite, :friend])
      sam.favorite(jon, scopes: [:friend])
      sam.favorite(beethoven, scopes: [:favorite])
      sam.favorite(rossini, scopes: [:favorite])
    end

    describe 'favorite' do
      it 'allows favoriting objects with scope' do
        expect { jon.favorite(beethoven, scope: :friend) }
          .to  change(Favorite, :count).by(1)
          .and change { jon.all_favorites(scope: :friend).size }.by(1)
          .and change { jon.favorited?(beethoven, scope: :friend) }
            .from(false).to(true)

        expect(jon.favorited?(beethoven, scope: :favorite)).to be false
      end
    end

    describe 'unfavorite' do
      it 'allows removing favorites by scope' do
        expect { jon.unfavorite(sam, scope: :favorite) }
          .to  change(Favorite, :count).by(-1)
          .and change { jon.all_favorites(scope: :favorite).size }.by(-1)
          .and change { jon.favorited?(sam, scope: :favorite) }
            .from(true).to(false)

        expect(jon.favorited?(sam, scope: :friend)).to be true
      end

      it 'allows removing multiple favorites at once' do
        expect { jon.unfavorite(sam, scopes: [:favorite, :friend]) }
          .to change(Favorite, :count).by(-2)
      end
    end

    describe 'favorites_by_type' do
      it 'only returns favorites of a given type by scope' do
        expect(sam.favorites_by_type('User', scope: :favorite)).to eq []
        expect(sam.favorites_by_type('Composer', scope: :favorite))
          .to eq [Favorite.find_by(favoritor: sam, favoritable: beethoven),
                  Favorite.find_by(favoritor: sam, favoritable: rossini)]
      end
    end

    describe 'all_favorites' do
      it 'returns all favorites by scope' do
        expect(jon.all_favorites(scope: :favorite))
          .to eq [Favorite.find_by(favoritor: jon, favoritable: sam)]
        expect(sam.all_favorites(scope: :favorite))
          .to eq [Favorite.find_by(favoritor: sam, favoritable: beethoven),
                  Favorite.find_by(favoritor: sam, favoritable: rossini)]
      end
    end

    describe 'favorited_by_type' do
      it 'only returns favorited objects of a given type' do
        expect(sam.favorited_by_type('User', scope: :favorite)).to eq []
        expect(sam.favorited_by_type('Composer', scope: :favorite))
          .to eq [beethoven, rossini]
      end
    end

    describe 'all_favorited' do
      it 'returns favorited objects' do
        expect(jon.all_favorited(scope: :favorite)).to eq [sam]
        expect(sam.all_favorited(scope: :favorite))
          .to eq [beethoven, rossini]
      end
    end
  end

  context 'with cascading' do
    before { jon.favorite(sam) }

    it 'cascades when destroying the favoritor' do
      expect { jon.destroy }
        .to  change(Favorite, :count).by(-1)
        .and change { jon.all_favorites.size }.by(-1)
    end

    it 'cascades when destroying the favoritable' do
      expect { sam.destroy }
        .to  change(Favorite, :count).by(-1)
        .and change { jon.all_favorites.size }.by(-1)
    end
  end
end
