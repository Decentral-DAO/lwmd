ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require "capybara/rails"
require 'helpers/factory_helper'
require 'database_cleaner'

Capybara.default_driver = :rack_test

DatabaseCleaner.strategy = :truncation

class UnitTest < MiniTest::Spec
  before do
    DatabaseCleaner.clean
  end

  after do

  end
end

class IntegrationTest < UnitTest
  include Capybara::DSL
  include Rails.application.routes.url_helpers
  include Warden::Test::Helpers
  Warden.test_mode!

  Capybara.register_driver :rack_test do |app|
    Capybara::RackTest::Driver.new app, \
      redirect_limit: 15,
      follow_redirects: true,
      respect_data_method: true
  end

  before do
    DatabaseCleaner.clean
  end

  after do

  end

  def sign_in(member)
    visit unauthenticated_root_path
    within("form#new_member") do
      fill_in 'member_email', with: member.email
      fill_in 'member_password', with: member.password
      click_on 'Log in'
    end
    page.must_have_content("Signed in successfully.")
  end

  def sign_in_as_member
    member = create(:member)
    sign_in(member)
    page.must_have_content "PTC Membership Database"
    within(".ui.main.menu") do
      must_have_content member.name
      must_have_content "Profile"
      must_have_content "Edit Account"
      must_have_content "Logout"
    end
    member
  end

  def sign_in_as_admin
    admin = create(:admin)
    sign_in(admin)
    within(".ui.main.menu") do
      must_have_content admin.name
      must_have_content "Memberships"
      must_have_content "Members"
      must_have_content "Profile"
      must_have_content "Edit Account"
      must_have_content "Logout"
    end
    admin
  end
end

class ApiTest < IntegrationTest
  include Rack::Test::Methods

  def app
    Capybara.app
  end
end
