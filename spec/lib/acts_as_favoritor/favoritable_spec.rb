# frozen_string_literal: true

require_relative '../../rails_helper'

RSpec.describe ActsAsFavoritor::Favoritable do
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

    describe 'favorited' do
      it 'returns all favorite records where the given instance ' \
         'was favorited' do
        expect(jon.favorited)
          .to eq [Favorite.find_by(favoritor: sam, favoritable: jon),
                  Favorite.find_by(favoritor: beethoven, favoritable: jon)]
      end
    end

    describe 'favoritors' do
      it 'returns favoritors who favorited the given instance' do
        expect(jon.favoritors).to eq [sam, beethoven]
      end

      it 'does not return blocked favoritors' do
        jon.block(beethoven)

        expect(jon.favoritors).to eq [sam]
      end
    end

    describe 'favoritors_by_type' do
      it 'returns favoritors who favorited the given instance ' \
         'and are of a specific type' do
        expect(jon.favoritors_by_type('User')).not_to be_a Array

        expect(jon.favoritors_by_type('User')).to eq [sam]
        expect(jon.favoritors_by_type('Composer')).to eq [beethoven]
      end
    end

    describe 'favorited_by?' do
      it 'returns true if the instance was favorited by the given record' do
        expect(jon.favorited_by?(beethoven)).to eq true
      end

      it 'returns false if the instance was not favorited ' \
         'by the given record' do
        expect(beethoven.favorited_by?(jon)).to eq false
      end
    end

    describe 'block' do
      it 'blocks the given favoritor' do
        expect { jon.block(beethoven) }.to change { jon.favoritors.size }.by(-1)
      end
    end

    describe 'unblock' do
      before { jon.block(beethoven) }

      it 'unblocks the given favoritor' do
        expect { jon.unblock(beethoven) }
          .to change { jon.favoritors.size }.by(1)
      end
    end

    describe 'blocked?' do
      it 'returns true if the given instance was blocked' do
        jon.block(beethoven)

        expect(jon.blocked?(beethoven)).to eq true
      end

      it 'returns false if the given instance was not blocked' do
        expect(jon.blocked?(beethoven)).to eq false
      end
    end

    describe 'blocked' do
      before { jon.block(beethoven) }

      it 'returns blocked favoritors' do
        expect(jon.blocked).to eq [beethoven]
      end
    end

    context 'with magic methods' do
      it 'responds to magic methods' do
        expect(jon).to respond_to(:user_favoritors)
      end

      it 'still raises a NoMethodError' do
        expect { jon.foobar }.to raise_error(NoMethodError)
      end

      it '*_favoritors returns favoritors of the given type' do
        expect(jon.user_favoritors).to eq [sam]
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

    describe 'favoritors' do
      it 'returns favoritors who favorited the given instance' do
        expect(jon.favoritors(scopes: [:friend])).to eq [sam]
      end
    end

    describe 'favoritors_by_type' do
      it 'returns favoritors who favorited the given instance ' \
         'and are of a specific type' do
        expect(jon.favoritors_by_type('User', scopes: [:friend])).to eq [sam]
        expect(jon.favoritors_by_type('Composer', scopes: [:friend])).to eq []
      end
    end

    describe 'favorited_by?' do
      it 'returns true if the instance was favorited by the given record' do
        expect(jon.favorited_by?(beethoven, scopes: [:favorite])).to eq true
      end

      it 'returns false if the instance was not favorited ' \
         'by the given record' do
        expect(jon.favorited_by?(beethoven, scopes: [:friend])).to eq false
      end
    end

    describe 'block' do
      it 'blocks the given favoritor' do
        beethoven.favorite(jon, scopes: [:friend])

        expect { jon.block(beethoven, scopes: [:friend]) }
          .to  change { jon.favoritors(scopes: [:friend]).size }.by(-1)
          .and change { jon.favoritors(scopes: [:favorite]).size }.by(0)
      end
    end

    describe 'unblock' do
      before { jon.block(beethoven, scopes: [:favorite]) }

      it 'unblocks the given favoritor' do
        expect { jon.unblock(beethoven, scopes: [:favorite]) }
          .to change { jon.favoritors(scopes: [:favorite]).size }.by(1)
      end
    end

    describe 'blocked?' do
      before { jon.block(beethoven, scopes: [:friend]) }

      it 'returns true if the given instance was blocked' do
        expect(jon.blocked?(beethoven, scopes: [:friend])).to eq true
      end

      it 'returns false if the given instance was not blocked' do
        expect(jon.blocked?(beethoven, scopes: [:favorite])).to eq false
      end
    end

    describe 'blocked' do
      before { jon.block(beethoven, scopes: [:friend]) }

      it 'returns blocked favoritors' do
        expect(jon.blocked(scopes: [:friend])).to eq [beethoven]
        expect(jon.blocked(scopes: [:favorite])).to eq []
      end
    end
  end
end
