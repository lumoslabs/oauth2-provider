require 'spec_helper'

describe OAuth2::Model::ResourceOwner do
  before do
    @owner  = Factory(:owner)
    @client = Factory(:client)
  end

  describe "#grant_access!" do
    it "creates an authorization between the owner and the client" do
      auth = double("auth")
      expect(OAuth2::Model::Authorization).to receive(:new).with(owner: @owner, client: @client).and_return(auth)
      expect(auth).to receive(:save)
      @owner.grant_access!(@client)
    end

    it "returns the authorization" do
      expect(@owner.grant_access!(@client)).to be_kind_of(OAuth2::Model::Authorization)
    end
  end

  describe "when there is an existing authorization" do
    before do
      @authorization = Factory(:authorization, owner: @owner, client: @client)
    end

    it "does not create a new one" do
      expect(OAuth2::Model::Authorization).not_to receive(:create)
    end

    it "updates the authorization with scopes" do
      @owner.grant_access!(@client, scopes: ['foo', 'bar'])
      @authorization.reload
      expect(@authorization.scopes.entries).to eq(['foo', 'bar'])
    end

    describe "with scopes" do
      before do
        @authorization.update_attribute(:scope, 'foo bar')
      end

      it "merges the new scopes with the existing ones" do
        @owner.grant_access!(@client, scopes: ['qux'])
        @authorization.reload
        expect(@authorization.scopes.entries).to eq(['foo', 'bar', 'qux'])
      end

      it "does not add duplicate scopes to the list" do
        @owner.grant_access!(@client, scopes: ['qux'])
        @owner.grant_access!(@client, scopes: ['qux'])
        @authorization.reload
        expect(@authorization.scopes.entries).to eq(['foo', 'bar', 'qux'])
      end
    end

    context "force_new is true" do
      it "creates a new authorization" do
        auth = double("auth")
        expect(OAuth2::Model::Authorization).to receive(:new).with(owner: @owner, client: @client).and_return(auth)
        expect(auth).to receive(:save)
        @owner.grant_access!(@client, force_new: true)
      end
    end
  end

  it "destroys its authorizations on destroy" do
    Factory(:authorization, owner: @owner, client: @client)
    @owner.destroy
    expect(OAuth2::Model::Authorization.count).to be_zero
  end

  describe "when scopes are specified" do
    it "creates an Authorization with given scopes" do
      @authorization = @owner.grant_access!(@client, scopes: ["a", "bunch", "of", "scopes"])
      expect(@authorization.scope).to eq("a bunch of scopes")
    end
  end

  describe "when a duration is specified" do
    it "creates an Authorization with correct expires_at attribute" do
      @authorization = @owner.grant_access!(@client, duration: 60)
      expect(@authorization.expires_at.to_i).to eq((@authorization.created_at + 60.seconds).to_i)
    end
  end
end
