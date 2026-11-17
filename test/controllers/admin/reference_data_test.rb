require "test_helper"

class Admin::ReferenceDataTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:admin) }

  test "lists weight classes with their bout counts" do
    get admin_weight_classes_path

    assert_response :ok
    assert_select "##{ActionView::RecordIdentifier.dom_id(weight_classes(:lightweight))} td", text: "2"
  end

  test "toggling a division stops it coming up on spins" do
    patch admin_weight_class_path(weight_classes(:lightweight)), params: { weight_class: { spinnable: false } }

    assert_redirected_to admin_weight_classes_path
    assert_not weight_classes(:lightweight).reload.spinnable?
    assert_not Fighter.pool_sizes.keys.map(&:first).include?(weight_classes(:lightweight).id)
  end

  test "editing an era saves valid dates" do
    patch admin_era_path(eras(:current)), params: { era: { name: "Current", starts_on: "2021-01-01", ends_on: "" } }

    assert_redirected_to admin_eras_path
    assert_nil eras(:current).reload.ends_on
  end

  test "an overlapping era comes back as a form error" do
    patch admin_era_path(eras(:modern)), params: { era: { name: "Modern", starts_on: "2016-01-01", ends_on: "2022-06-30" } }

    assert_response :unprocessable_content
    assert_select ".admin__errors", /overlaps another era/
    assert_equal Date.new(2020, 12, 31), eras(:modern).reload.ends_on
  end

  test "non-admins are refused" do
    sign_in_as users(:one)

    patch admin_weight_class_path(weight_classes(:lightweight)), params: { weight_class: { spinnable: false } }

    assert_response :forbidden
    assert weight_classes(:lightweight).reload.spinnable?
  end
end
