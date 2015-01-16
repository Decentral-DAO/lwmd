require 'test_helper'

class MemberIntegrationTest < IntegrationTest

  describe "an admin" do
    before do
      @admin = sign_in_as_admin
    end

    it "can view a list of members" do
      @member = create(:member)
      visit members_path
      within ("tbody") do
        must_have_css(".green.checkmark.box.icon")
        must_have_content @member.name
        must_have_content @member.email
        must_have_content @member.address.full_address
        must_have_content @member.cell_phone.phony_formatted(normalize: :US, spaces: '-')
      end
    end

    it "adds a new member" do
      visit new_member_path
      within("form.new_member") do
        fill_in 'First Name', :with => 'First'
        fill_in 'Last Name', :with => 'Last'
        fill_in 'Email', :with => 'user@example.com'
        fill_in 'Birthdate', :with => '3/3/1978'
        fill_in 'USAT Number', :with => '20120434234'
        fill_in 'Cell phone', :with => "555-555-1212"
        fill_in 'Full address', :with => '123 Fake Street, Anytown, KS 55555'
        fill_in 'Notes', :with => 'These are notes'
      end
      click_button 'Add Member'
      ActionMailer::Base.deliveries.last[:to].to_s.must_equal "user@example.com"
      ActionMailer::Base.deliveries.last[:subject].to_s.must_include "Pittsburgh Triathlon Club"
      page.must_have_css('.ui.blue.message.closable')
      Address.last.city.must_equal 'Anytown'
    end

    it "wont add a member with missing or invalid" do
      visit new_member_path
      click_button 'Add Member'
      page.must_have_css('.ui.red.message')
      page.must_have_content("First name can't be blank")
      page.must_have_content("Last name can't be blank")
      page.must_have_content("Email can't be blank")
      page.must_have_content("Cell phone is required if home phone isn't given")
      page.must_have_content("Home phone is required if cell phone isn't given")
    end

    it "edits a member" do
      @member = create(:member)
      visit edit_member_path(@member)
      within("form.edit_member") do
        find('#member_last_name').value.must_equal @member.last_name
        fill_in 'member_cell_phone', :with => "412-123-3333"
        fill_in 'member_address_attributes_full_address', :with => '123 Fake Street, Anytown, KS 55555'
      end
      click_button 'Save'
      find('.ui.blue.message.closable')
      visit edit_member_path(@member)
      find('#member_cell_phone').value.must_equal "14121233333"
      find('#member_address_attributes_full_address').value.must_have_content "Anytown"
    end

    it "deactivates a member" do
      @member = create(:member)
      visit edit_member_path(@member)
      within("form.edit_member") do
        find("#member_active").set(false)
      end
      click_button 'Save'
      within("tr##{@member.id}") do
        page.wont_have_css('i')
      end
    end
  end

  describe "a member" do

    it "can log in and log out of the app" do
      @member = create(:member, password: "password1")
      sign_in(@member)
      page.must_have_content("Signed in successfully.")
      click_link('Logout')
      page.must_have_content("PTC Membership Database")
    end

    it "knows whether a user has a profile photo" do
      @member = create(:member)
      sign_in(@member)
      page.must_have_content("Update your profile photo")
      @member.update_attributes!(avatar_updated_at: Date.today)
      visit member_root_path
      page.wont_have_content("Update your profile photo")
    end
  end

  describe "an invited member" do

    before do
      OmniAuth.config.test_mode = true
      OmniAuth.config.add_mock(:facebook, {:uid => '12345'})
      OmniAuth.config.add_mock(:google, {:uid => '54321'})
      @admin = create(:member)
      @member = create(:member)
      @member.invite!(@admin)
      page.driver.browser.set_cookie('token=#{@member.raw_invitation_token}')
    end

    it "sets up an account from an invitation" do

      visit accept_member_invitation_path(invitation_token: @member.raw_invitation_token)
      page.must_have_content("Welcome to the Pittsburgh Triathlon Club, #{@member.first_name}!")
      find("#member_invitation_token", visible: false).value.must_equal @member.raw_invitation_token
      fill_in 'member_password', with: "password1"
      fill_in 'member_password_confirmation', with: "password1"
      click_button 'Set up your account'
      page.must_have_css('.ui.blue.message.closable')
      page.must_have_content("You are now signed in.")
      page.must_have_content @member.name
    end

    it "can use Facebook to connect" do

      visit accept_member_invitation_path(invitation_token: @member.raw_invitation_token)
      within('form#edit_member') do
        find('#facebook_login').click
      end
      page.must_have_css('.ui.blue.message.closable')
      page.must_have_content("Successfully authenticated from Facebook account")
      page.driver.browser.clear_cookies
      logout(:member)
      visit unauthenticated_root_path
      within('form#new_member') do
        find('#facebook_login').click
      end
      page.must_have_content("Successfully authenticated from Facebook account")
    end

    it "can use Google Plus to connect" do

      visit accept_member_invitation_path(invitation_token: @member.raw_invitation_token)
      within('form#edit_member') do
        find('#google_login').click
      end
      page.must_have_css('.ui.blue.message.closable')
      page.must_have_content("Successfully authenticated from Google account")
      page.driver.browser.clear_cookies
      logout(:member)
      visit unauthenticated_root_path
      within('form#new_member') do
        find('#google_login').click
      end
      page.must_have_content("Successfully authenticated from Google account")
    end

    it "knows when an uninvited member can't omniauth" do
      visit unauthenticated_root_path
      within('form#new_member') do
        find('#facebook_login').click
      end
      page.must_have_content("Sorry! We could not connect you with any member account.")
    end
  end
end
