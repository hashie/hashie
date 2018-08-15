require "spec_helper"

context "load yaml" do
  it do
    mash = Hashie::Mash.load("spec/fixtures/yaml_with_aliases.yml")
    expect(mash.company_a.accounts.admin.password).to eq "secret"
  end
end
