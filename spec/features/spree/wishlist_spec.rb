RSpec.feature 'Wishlist', :js do
  given(:user) { create(:user) }
  given(:product) { create(:product) }

  context 'with no wishlist' do

    context 'create' do
      background do
        sign_in_as! user
      end

      scenario 'when user has no existing wishlist' do
        visit spree.product_path(product)
        click_button 'Add to wishlist'

        expect(page).to have_content user.wishlists.first.name
      end

      scenario 'when user has an existing wishlist' do
        wishlist = create(:wishlist, user: user)

        visit spree.account_path
        click_link wishlist.name
        click_link 'Create new wishlist'

        fill_in 'Name', with: 'A New Wishlist Name'
        click_button 'Create'

        expect(page).to have_content 'A New Wishlist Name'
      end

      scenario 'when user makes use of the new wishlist path' do
        visit spree.new_wishlist_path
        fill_in 'Name', with: 'A New Wishlist Name'
        click_button 'Create'

        expect(page).to have_content 'A New Wishlist Name'
      end
    end
  end

  context 'with existing wishlist' do
    given(:wishlist) { create(:wishlist) }
    given(:user)     { wishlist.user }

    background do
      sign_in_as! user
    end

    context 'show', :focus do
      background do
        wishlist.wished_products << Spree::WishedProduct.new(variant: product.master)
      end

      context 'wishlist has a current product' do
        scenario 'it displays the product' do
          visit spree.account_path
          click_link wishlist.name

          expect(page).to have_content(product.name)
        end
      end

      context 'wishlist has a discarded product' do
        background do
          product.discard
        end

        scenario 'it does not display the product' do
          visit spree.account_path
          click_link wishlist.name

          expect(page).to_not have_content(product.name)
        end
      end
    end

    context 'edit' do
      scenario 'edit a wishlists name' do
        visit_edit_wishlist

        fill_in 'Name', with: 'A New Wishlist Name'
        click_button 'Update'

        expect(page).to have_content 'A New Wishlist Name'
      end

      context 'edit a wishlists is_private' do
        scenario 'set wishlist from private to public' do
          wishlist.is_private = true
          wishlist.save

          visit_edit_wishlist

          uncheck 'is private'
          click_button 'Update'

          expect(page).to have_checked_field 'wishlist_is_private_false'
        end

        scenario 'set wishlist from public to private' do
          wishlist.is_private = false
          wishlist.save

          visit_edit_wishlist

          check 'is private'
          click_button 'Update'

          expect(page).to have_checked_field 'wishlist_is_private_true'
        end
      end

      context 'edit a wishlists is_default' do
        scenario 'set wishlist from default to non-default' do
          wishlist.is_default = true
          wishlist.save

          visit_edit_wishlist

          uncheck 'is default'
          click_button 'Update'
          click_link 'Edit wishlist'

          expect(page).to have_unchecked_field 'is default'
        end

        scenario 'set wishlist from non-default to default' do
          wishlist.is_default = false
          wishlist.save

          visit_edit_wishlist

          check 'is default'
          click_button 'Update'
          click_link 'Edit wishlist'

          expect(page).to have_checked_field 'is default'
        end
      end
    end

    context 'delete' do
      scenario 'delete a users wishlist' do
        visit_edit_wishlist
        click_link 'Delete wishlist'
        expect(page).not_to have_content wishlist.name
      end
    end
  end

  context 'wishlist privacy settings', type: :controller do
    given(:wishlist) { create(:wishlist) }

    context 'when logged out' do

      scenario 'visit a private wishlist' do
        wishlist.update_attributes(is_private: true)

        visit spree.wishlist_path(wishlist)

        expect(current_path).not_to match(spree.wishlist_path(wishlist))
        expect(page).not_to have_content wishlist.name
      end

      scenario 'visit a public wishlist' do
        wishlist.update_attributes(is_private: false)

        visit spree.wishlist_path(wishlist)

        expect(current_path).to match(spree.wishlist_path(wishlist))
        expect(page).to have_content wishlist.name
      end
    end

    context 'when logged in', type: :controller do
      given(:user_1)      { create(:user) }
      given(:user_2)      { create(:user) }

      background do
        sign_in_as! user_1
      end

      scenario 'visit own private wishlist' do
        wishlist.is_private = true
        wishlist.user = user_1
        wishlist.save

        visit spree.wishlist_path(wishlist)

        expect(current_path).to match(spree.wishlist_path(wishlist))
        expect(page).to have_content wishlist.name
      end

      scenario 'visit other private wishlist' do
        wishlist.is_private = true
        wishlist.user = user_2
        wishlist.save

        visit spree.wishlist_path(wishlist)

        expect(current_path).not_to match(spree.wishlist_path(wishlist))
        expect(page).not_to have_content wishlist.name
      end
    end
  end

  private

  def visit_edit_wishlist
    visit spree.account_path
    click_link wishlist.name
    click_link 'Edit wishlist'
  end
end