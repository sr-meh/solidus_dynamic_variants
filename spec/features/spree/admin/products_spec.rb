# frozen_string_literal: true

require 'spec_helper'

RSpec.feature "Admin Products" do
  stub_authorization!

  context "update product" do
    let(:product) { create(:product) }

    it "should set dynamic variants" do
      visit spree.admin_product_path(product)
      #find(:css, "#product_dynamic_variants").set(true)
      page.check("Dynamic Variants")
      click_button "Update"
      expect(page).to have_content("successfully updated!")
      expect(page.has_checked_field?("product_dynamic_variants")).to be true
      expect(Spree::Product.last.dynamic_variants).to be true
    end

  end
end
