require 'rails_helper'

RSpec.describe BillingsController, type: :request do
  include Devise::Test::IntegrationHelpers

  let(:organization) { create(:organization, :with_subscription, subdomain: 'testorg') }
  let(:user)         { create(:user) }
  let(:plan)         { Plan.find_by!(slug: 'basic') }

  before do
    create(:membership, user: user, organization: organization, role: :owner)
  end

  after do
    ActsAsTenant.current_tenant = nil
  end

  describe 'GET /billing' do
    context 'as authenticated owner' do
      before do
        sign_in user, scope: :user
      end

      it 'returns 200 status' do
        get billing_url(host: 'testorg.localhost')
        expect(response).to have_http_status(:ok)
      end

      it 'displays billing page content' do
        get billing_url(host: 'testorg.localhost')
        expect(response.body).to include('Billing')
      end

      it 'shows subscription and plans' do
        get billing_url(host: 'testorg.localhost')
        body = response.body
        expect(body).to(include('Current Plan')) || expect(body).to(include('Subscription'))
      end
    end

    context 'as non-owner' do
      before do
        user.memberships.update_all(role: :member)
        sign_in user, scope: :user
      end

      it 'redirects to login' do
        get billing_url(host: 'testorg.localhost')
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'without authentication' do
      it 'requires login' do
        get billing_url(host: 'testorg.localhost')
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /billing/success' do
    before do
      sign_in user, scope: :user
    end

    it 'redirects to billing' do
      get success_billing_url(host: 'testorg.localhost')
      expect(response).to redirect_to(billing_url(host: 'testorg.localhost'))
    end

    it 'sets success flash message' do
      get success_billing_url(host: 'testorg.localhost')
      expect(flash[:notice]).to be_present
    end
  end

  describe 'GET /billing/portal' do
    let(:stripe_customer) { double(id: 'cus_test123') }
    let(:stripe_portal)   { double(url: 'https://billing.stripe.com/test') }

    before do
      sign_in user, scope: :user
      organization.subscription.update!(stripe_customer_id: 'cus_test123')
      allow(Stripe::Customer).to receive(:retrieve).and_return(stripe_customer)
      allow(Stripe::BillingPortal::Session).to receive(:create).and_return(stripe_portal)
    end

    it 'redirects to Stripe portal' do
      get portal_billing_url(host: 'testorg.localhost')
      expect(response).to redirect_to('https://billing.stripe.com/test')
    end

    it 'requires owner access' do
      user.memberships.update_all(role: :member)
      get portal_billing_url(host: 'testorg.localhost')
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe 'authorization' do
    context 'as member' do
      before do
        user.memberships.update_all(role: :member)
        sign_in user, scope: :user
      end

      it 'denies billing access' do
        get billing_url(host: 'testorg.localhost')
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'as admin' do
      before do
        user.memberships.update_all(role: :admin)
        sign_in user, scope: :user
      end

      it 'denies billing access' do
        get billing_url(host: 'testorg.localhost')
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
