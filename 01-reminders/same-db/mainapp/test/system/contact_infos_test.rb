require "application_system_test_case"

class ContactInfosTest < ApplicationSystemTestCase
  setup do
    @contact_info = contact_infos(:one)
  end

  test "visiting the index" do
    visit contact_infos_url
    assert_selector "h1", text: "Contact Infos"
  end

  test "creating a Contact info" do
    visit contact_infos_url
    click_on "New Contact Info"

    fill_in "Email", with: @contact_info.email
    fill_in "Name", with: @contact_info.name
    fill_in "Phone", with: @contact_info.phone
    click_on "Create Contact info"

    assert_text "Contact info was successfully created"
    click_on "Back"
  end

  test "updating a Contact info" do
    visit contact_infos_url
    click_on "Edit", match: :first

    fill_in "Email", with: @contact_info.email
    fill_in "Name", with: @contact_info.name
    fill_in "Phone", with: @contact_info.phone
    click_on "Update Contact info"

    assert_text "Contact info was successfully updated"
    click_on "Back"
  end

  test "destroying a Contact info" do
    visit contact_infos_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Contact info was successfully destroyed"
  end
end
