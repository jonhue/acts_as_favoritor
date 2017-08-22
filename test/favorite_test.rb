require File.dirname(__FILE__) + '/test_helper'

class FavoriteTest < ActiveSupport::TestCase

    # Replace with real tests
    def test_assert_true_should_be_true
        assert true
    end

    context 'configuration with setters' do
        should 'contain custom parents' do
            ActsAsFavoritor.custom_parent_classes = [CustomRecord]

            assert_equal [CustomRecord], ActsAsFavoritor.custom_parent_classes
        end
    end

    context '#setup' do
        should 'contain custom parents via setup' do
            ActsAsFavoritor.setup do |c|
                c.custom_parent_classes = [CustomRecord]
            end

            assert_equal [CustomRecord], ActsAsFavoritor.custom_parent_classes
        end
    end

end
