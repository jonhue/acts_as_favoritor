# frozen_string_literal: true

require_relative '../rails_helper'

RSpec.describe 'acts_as_favoritable' do
  let(:sam) { create :sam }
  let(:jon) { create :jon }
  let(:bob) { create :bob }

  context 'without scopes' do
    before do
      jon.favorite(sam)
      bob.favorite(sam)
      sam.favorite(jon)
    end

    it 'responds to instance methods' do
      expect(sam).to respond_to(:favoritors_count)
      expect(sam).to respond_to(:favoritors)
      expect(sam).to respond_to(:favorited_by?)
    end

    describe 'favoritors_count' do
      it 'returns the number of objects that favorited an instance' do
        expect { jon.favorite(bob) }.to change(bob, :favoritors_count).by(1)
      end
    end

    describe 'favoritors' do
      it 'returns favorited objects' do
        expect(jon.favoritors).to eq [sam]
        expect(sam.favoritors).to eq [jon, bob]
      end

      it 'accepts AR options' do
        expect(jon.favoritors(limit: 0)).to eq []
      end
    end

    describe 'favorited_by?' do
      it 'returns true when an instance was favorited by the given object' do
        expect(sam.favorited_by?(jon)).to eq true
      end

      it 'returns false when an instance was not favorited ' \
         'by the given object' do
        expect(bob.favorited_by?(jon)).to eq false
      end
    end

    describe 'favoritors_by_type' do
      it 'only returns favoritors of a given type' do
        expect(sam.favoritors_by_type('User')).to eq [jon, bob]
      end

      it 'accepts AR options' do
        expect(jon.favoritors_by_type('User', limit: 0)).to eq []
      end
    end

    describe 'block/unblock' do
      it 'a favoritable cannot be favorited when the favoritor was blocked' do
        expect { sam.block(jon) }.to change { jon.favorited?(sam) }
          .from(true).to(false)
        expect { sam.unblock(jon) }.to change { jon.favorited?(sam) }
          .from(false).to(true)
      end
    end

    context 'with magic methods' do
      it 'responds to magic methods' do
        expect(sam).to respond_to(:user_favoritors)
        expect(sam).to respond_to(:count_user_favoritors)
      end

      it 'still raises a NoMethodError' do
        expect { sam.foobar }.to raise_error(NoMethodError)
      end

      it '*_favoritors returns favoritors' do
        expect(jon.user_favoritors).to eq [sam]
        expect(sam.user_favoritors).to eq [jon, bob]
        expect(bob.user_favoritors).to eq []
      end

      it 'count_*_favoritors returns favoritors' do
        expect(jon.count_user_favoritors).to eq 1
        expect(sam.count_user_favoritors).to eq 2
        expect(bob.count_user_favoritors).to eq 0
      end
    end
  end

  context 'with scopes' do
    before do
      jon.favorite(sam, scope: [:favorite, :friend])
      bob.favorite(sam, scope: [:friend])
      sam.favorite(jon, scope: [:favorite])
    end

    describe 'favoritors_count' do
      it 'returns the number of objects by scope that favorited an instance' do
        expect { jon.favorite(bob, scope: [:favorite]) }
          .to change { bob.favoritors_count(scope: [:favorite]) }.by(1)
      end
    end

    describe 'favoritors' do
      it 'returns favorited objects by scope' do
        expect(jon.favoritors(scope: [:favorite])).to eq [sam]
        expect(sam.favoritors(scope: [:favorite])).to eq [jon]
      end
    end

    describe 'favorited_by?' do
      it 'returns true when an instance was favorited by the given object' do
        expect(sam.favorited_by?(jon, scope: [:favorite])).to eq true
      end

      it 'returns false when an instance was not favorited ' \
         'by the given object' do
        expect(sam.favorited_by?(bob, scope: [:favorite])).to eq false
      end
    end

    describe 'favoritors_by_type' do
      it 'only returns favoritors of a given type by scope' do
        expect(sam.favoritors_by_type('User', scope: [:favorite])).to eq [jon]
      end
    end
  end

  context 'with cascading' do
    before { jon.favorite(sam) }

    it 'cascades when destroying the favoritor' do
      expect { jon.destroy }.to change(Favorite, :count).by(-1)
        .and change(sam, :favoritors_count).by(-1)
    end

    it 'cascades when destroying the favoritable' do
      expect { sam.destroy }.to change(Favorite, :count).by(-1)
        .and change(sam, :favoritors_count).by(-1)
    end
  end
end
