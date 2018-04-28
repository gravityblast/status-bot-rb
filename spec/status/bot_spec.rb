require "spec_helper"

RSpec.describe Status::Bot do
  it "has a version number" do
    expect(Status::VERSION).not_to be nil
  end

  it "does something useful" do
    expect(false).to eq(true)
  end
end
