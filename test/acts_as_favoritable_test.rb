require File.dirname(__FILE__) + '/test_helper'

class ActsAsFavoritableTest < ActiveSupport::TestCase

    context 'instance methods' do
        setup do
            @sam = FactoryGirl.create :sam
        end

        should 'be defined' do
            assert @sam.respond_to? :favoritors_count
            assert @sam.respond_to? :favoritors
            assert @sam.respond_to? :favorited_by?
        end
    end

    context 'acts_as_favoritable' do
        setup do
            @sam = FactoryGirl.create :sam
            @jon = FactoryGirl.create :jon
            @oasis = FactoryGirl.create :oasis
            @metallica = FactoryGirl.create :metallica
            @green_day = FactoryGirl.create :green_day
            @blink_182 = FactoryGirl.create :blink_182
            @sam.favorite @jon
        end

        context 'favoritors_count' do
            should 'return the number of favoritors' do
                assert_equal 0, @sam.favoritors_count
                assert_equal 1, @jon.favoritors_count
            end

            should 'return the proper number of multiple favoritors' do
                @bob = FactoryGirl.create :bob
                @sam.favorite @bob
                assert_equal 0, @sam.favoritors_count
                assert_equal 1, @jon.favoritors_count
                assert_equal 1, @bob.favoritors_count
            end
        end

        context 'favoritors' do
            should 'return users' do
                assert_equal [], @sam.favoritors
                assert_equal [@sam], @jon.favoritors
            end

            should 'return users (multiple favoritors)' do
                @bob = FactoryGirl.create :bob
                @sam.favorite @bob
                assert_equal [], @sam.favoritors
                assert_equal [@sam], @jon.favoritors
                assert_equal [@sam], @bob.favoritors
            end

            should 'return users (multiple favoritors, complex)' do
                @bob = FactoryGirl.create :bob
                @sam.favorite @bob
                @jon.favorite @bob
                assert_equal [], @sam.favoritors
                assert_equal [@sam], @jon.favoritors
                assert_equal [@sam, @jon], @bob.favoritors
            end

            should 'accept AR options' do
                @bob = FactoryGirl.create :bob
                @bob.favorite @jon
                assert_equal 1, @jon.favoritors(limit: 1).count
            end
        end

        context 'favorited_by' do
            should 'return_favoritor_status' do
                assert_equal true, @jon.favorited_by?(@sam)
                assert_equal false, @sam.favorited_by?(@jon)
            end
        end

        context 'destroying a favoritable' do
            setup do
                @jon.destroy
            end

            should_change('Favorite count', by: -1) { Favorite.count }
            should_change('@sam.all_favorited.size', by: -1) { @sam.all_favorited.size }
        end

        context 'get favorite record' do
            setup do
                @bob = FactoryGirl.create :bob
                @favorite = @bob.favorite @sam
            end

            should 'return favorite record' do
                assert_equal @favorite, @sam.get_favorite_for(@bob)
            end

            should 'return nil' do
                assert_nil @sam.get_favorite_for(@jon)
            end
        end

        context 'blocks' do
            setup do
        @bob = FactoryGirl.create :bob
        @jon.block @sam
        @jon.block @bob
        end

        should 'accept AR options' do
            assert_equal 1, @jon.blocks(limit: 1).count
        end
        end

        context 'blocking a favoritor' do
            context 'in my favorited list' do
                setup do
                    @jon.block @sam
                end

                should 'remove him from favoritors' do
                    assert_equal 0, @jon.favoritors_count
                end

                should 'add him to the blocked favoritors' do
                    assert_equal 1, @jon.blocked_favoritors_count
                end

                should 'not be able to favorite again' do
                    @jon.favorite @sam
                    assert_equal 0, @jon.favoritors_count
                end

                should 'not be present when listing favoritors' do
                    assert_equal [], @jon.favoritors
                end

                should 'be in the list of blocks' do
                    assert_equal [@sam], @jon.blocks
                end
            end

            context 'not in my favorited list' do
                setup do
                    @sam.block @jon
                end

                should 'add him to the blocked favoritors' do
                    assert_equal 1, @sam.blocked_favoritors_count
                end

                should 'not be able to favorite again' do
                    @sam.favorite @jon
                    assert_equal 0, @sam.favoritors_count
                end

                should 'not be present when listing favoritors' do
                    assert_equal [], @sam.favoritors
                end

                should 'be in the list of blocks' do
                    assert_equal [@jon], @sam.blocks
                end
            end
        end

        context 'unblocking a blocked favorite' do
            setup do
                @jon.block @sam
                @jon.unblock @sam
            end

            should 'not include the unblocked user in the list of favoritors' do
                assert_equal [], @jon.favoritors
            end

            should 'remove him from the blocked favoritors' do
                assert_equal 0, @jon.blocked_favoritors_count
                assert_equal [], @jon.blocks
            end
        end

        context 'unblock a non-existent favorite' do
            setup do
                @sam.remove_favorite @jon
                @jon.unblock @sam
            end

            should 'not be in the list of favoritors' do
                assert_equal [], @jon.favoritors
            end

            should 'not be in the blocked favoritors count' do
                assert_equal 0, @jon.blocked_favoritors_count
            end

            should 'not be in the blocks list' do
                assert_equal [], @jon.blocks
            end
        end

        context 'favoritors_by_type' do
            setup do
                @sam.favorite @oasis
                @jon.favorite @oasis
            end

            should 'return the favoritors for given type' do
                assert_equal [@sam], @jon.favoritors_by_type('User')
                assert_equal [@sam, @jon], @oasis.favoritors_by_type('User')
            end

            should 'not return block favoritors in the favoritors for a given type' do
                @oasis.block @jon
                assert_equal [@sam], @oasis.favoritors_by_type('User')
            end

            should 'return the count for favoritors_by_type_count for a given type' do
                assert_equal 1, @jon.favoritors_by_type_count('User')
                assert_equal 2, @oasis.favoritors_by_type_count('User')
            end

            should 'not count blocked favorites in the count' do
                @oasis.block @sam
                assert_equal 1, @oasis.favoritors_by_type_count('User')
            end
        end

        context 'favoritors_with_sti' do
            setup do
                @sam.favorite @green_day
                @sam.favorite @blink_182
            end

            should 'return the favoritors for given type' do
                assert_equal @sam.favorites_by_type('Band').first.favoritable, @green_day.becomes(Band)
                assert_equal @sam.favorites_by_type('Band').second.favoritable, @blink_182.becomes(Band)
                assert @green_day.favoritors_by_type('User').include?(@sam)
                assert @blink_182.favoritors_by_type('User').include?(@sam)
            end
        end

        context 'method_missing' do
            setup do
                @sam.favorite @oasis
                @jon.favorite @oasis
            end

            should 'return the favoritors for given type' do
                assert_equal [@sam], @jon.user_favoritors
                assert_equal [@sam, @jon], @oasis.user_favoritors
            end

            should 'not return block favoritors in the favoritors for a given type' do
                @oasis.block @jon
                assert_equal [@sam], @oasis.user_favoritors
            end

            should 'return the count for favoritors_by_type_count for a given type' do
                assert_equal 1, @jon.count_user_favoritors
                assert_equal 2, @oasis.count_user_favoritors
            end

            should 'not count blocked favorites in the count' do
                @oasis.block @sam
                assert_equal 1, @oasis.count_user_favoritors
            end
        end

        context 'respond_to?' do
            should 'advertise that it responds to favorited methods' do
                assert @oasis.respond_to?(:user_favoritors)
                assert @oasis.respond_to?(:user_favoritors_count)
            end

            should 'return false when called with a nonexistent method' do
                assert (not @oasis.respond_to?(:foobar))
            end
        end

    end
end
