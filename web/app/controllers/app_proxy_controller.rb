# frozen_string_literal: true

class AppProxyController < ApplicationController
  include ShopifyApp::AppProxyVerification

  def index
    redirect_to '/a/trial/returns/search', allow_other_hosts: true
  end
end
