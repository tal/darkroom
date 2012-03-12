require 'spec_helper'

describe Darkroom do
  let(:obj) {TestKlass.new}
  it "should have modules included" do
    obj.should be_a Darkroom::Plugins::Sizing
    obj.should be_a Darkroom::Plugins::S3
  end
end