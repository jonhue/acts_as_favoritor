require File.dirname(__FILE__) + '/test_helper'

class ActsAsFavoritorTest < ActiveSupport::TestCase

    context 'instance methods' do
        setup do
            @sam = FactoryGirl.create :sam
        end

        should 'be defined' do
            assert @sam.respond_to? :favorited?
            assert @sam.respond_to? :favorites_count
            assert @sam.respond_to? :favorite
            assert @sam.respond_to? :remove_favorite
            assert @sam.respond_to? :favorites_by_type
            assert @sam.respond_to? :all_favorites
        end
    end

    context 'acts_as_favoritor' do
        setup do
            @sam = FactoryGirl.create :sam
            @jon = FactoryGirl.create :jon
            @oasis = FactoryGirl.create :oasis
            @sam.favorite @jon
            @sam.favorite @oasis
        end

        context 'favorited' do
            should 'return favorited_status' do
                assert_equal true, @sam.favorited?(@jon)
                assert_equal false, @jon.favorited?(@sam)
            end

            should 'return favorites_count' do
                assert_equal 2, @sam.favorites_count
                assert_equal 0, @jon.favorites_count
            end
        end

        context 'favorite a friend' do
            setup do
                @jon.favorite @sam
            end

            should_change('Favorite count', by: 1) { Favorite.count }
            should_change('@jon.favorites_count', by: 1) { @jon.favorites_count }

            should "set the favoritor" do
                assert_equal @jon, Favorite.last.favoritor
            end

            should "set the favoritable" do
                assert_equal @sam, Favorite.last.favoritable
            end
        end

        context "favorite yourself" do
            setup do
                @jon.favorite @jon
            end

            should_not_change('Favorite count') { Favorite.count }
            should_not_change('@jon.favorites_count') { @jon.favorites_count }

            should 'not set the favoritor' do
                assert_not_equal @jon, Favorite.last.favoritor
            end

            should 'not set the favoritable' do
                assert_not_equal @jon, Favorite.last.favoritable
            end
        end

        context 'remove_favorite' do
            setup do
                @sam.remove_favorite @jon
            end

            should_change('Favorite count', by: -1) { Favorite.count }
            should_change('@sam.favorites_count', by: -1) { @sam.favorites_count }
        end

        context 'favorites' do
            setup do
                @band_favorite = Favorite.where('favoritor_id = ? and favoritor_type = "User" and favoritable_id = ? and favoritable_type = "Band"', @sam.id, @oasis.id).first
                @user_favorite = Favorite.where('favoritor_id = ? and favoritor_type = "User" and favoritable_id = ? and favoritable_type = "User"', @sam.id, @jon.id).first
            end

            context 'favorites_by_type' do
                should 'only return requested favorites' do
                    assert_equal [@band_favorite], @sam.favorites_by_type('Band')
                    assert_equal [@user_favorite], @sam.favorites_by_type('User')
                end

                should 'accept AR options' do
                    @metallica = FactoryGirl.create :metallica
                    @sam.favorite @metallica
                    assert_equal 1, @sam.favorites_by_type('Band', limit: 1).count
                end
            end

            context 'favorited_by_type_count' do
                should 'return the count of the requested type' do
                    @metallica = FactoryGirl.create :metallica
                    @sam.favorite @metallica
                    assert_equal 2, @sam.favorited_by_type_count('Band')
                    assert_equal 1, @sam.favorited_by_type_count('User')
                    assert_equal 0, @jon.favorited_by_type_count('Band')
                    @jon.block @sam
                    assert_equal 0, @sam.favorited_by_type_count('User')
                end
            end

            context 'all_favorites' do
                should 'return all favorites' do
                    assert_equal 2, @sam.all_favorites.size
                    assert @sam.all_favorites.include?(@band_favorite)
                    assert @sam.all_favorites.include?(@user_favorite)
                    assert_equal [], @jon.all_favorites
                end

                should 'accept AR options' do
                    assert_equal 1, @sam.all_favorites(limit: 1).count
                end
            end
        end

        context 'all_favorited' do
            should 'return the actual favorite records' do
                assert_equal 2, @sam.all_favorited.size
                assert @sam.all_favorited.include?(@oasis)
                assert @sam.all_favorited.include?(@jon)
                assert_equal [], @jon.all_favorited
            end

            should 'accept AR limit option' do
                assert_equal 1, @sam.all_favorited(limit: 1).count
            end

            should 'accept AR where option' do
                assert_equal 1, @sam.all_favorited(where: { id: @oasis.id }).count
            end
        end

        context 'favorited_by_type' do
            should 'return only requested records' do
                assert_equal [@oasis], @sam.favorited_by_type('Band')
                assert_equal [@jon], @sam.favorited_by_type('User')
            end

            should 'accept AR options' do
                @metallica = FactoryGirl.create :metallica
                @sam.favorite @metallica
                assert_equal 1, @sam.favorited_by_type('Band', limit: 1).to_a.size
            end
        end

        context 'method_missing' do
            should 'call favorited_by_type' do
                assert_equal [@oasis], @sam.favorited_bands
                assert_equal [@jon], @sam.favorited_users
            end

            should 'call favorited_by_type_count' do
                @metallica = FactoryGirl.create :metallica
                @sam.favorite @metallica
                assert_equal 2, @sam.favorited_bands_count
                assert_equal 1, @sam.favorited_users_count
                assert_equal 0, @jon.favorited_bands_count
                @jon.block @sam
                assert_equal 0, @sam.favorited_users_count
            end

            should 'raise on no method' do
                assert_raises (NoMethodError) { @sam.foobar }
            end
        end

        context 'respond_to?' do
            should 'advertise that it responds to favorited methods' do
                assert @sam.respond_to?(:favorited_users)
                assert @sam.respond_to?(:favorited_users_count)
            end

            should 'return false when called with a nonexistent method' do
                assert (not @sam.respond_to?(:foobar))
            end
        end

        context 'destroying favoritor' do
            setup do
                @jon.destroy
            end

            should_change('Favorite.count', by: -1) { Favorite.count }
            should_change('@sam.favorites_count', by: -1) { @sam.favorites_count }
        end

        context "blocked by favoritable" do
            setup do
                @jon.block @sam
            end

            should 'return favorited_status' do
                assert_equal false, @sam.favorited?(@jon)
            end

            should 'return favorites_count' do
                assert_equal 1, @sam.favorites_count
            end

            should 'not return record of the blocked favorites' do
                assert_equal 1, @sam.all_favorites.size
                assert !@sam.all_favorites.include?(@user_favorite)
                assert !@sam.all_favorited.include?(@jon)
                assert_equal [], @sam.favorited_by_type('User')
                assert_equal [], @sam.favorites_by_type('User')
                assert_equal [], @sam.favorited_users
            end
        end
    end

end
