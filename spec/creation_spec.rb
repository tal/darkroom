require 'spec_helper'

module ImageRead
  attr_accessor :original_meta, :shot_at
end

describe Darkroom do
  let(:obj) {TestKlass.new}

  describe '#image=' do

    before(:all) do
      obj.extend ImageRead
    end

    it "should accept a url" do
      obj.image = 'http://placekitten.com/200/300'
      obj.original_meta.should include("mime_type"=>"image/jpeg", "geometry_x"=>200, "geometry_y"=>300)
    end

    it "should accept a path" do
      obj.image = 'test_images/testimg.jpg'
      obj.original_meta.should include("mime_type"=>"image/jpeg", "geometry_x"=>200, "geometry_y"=>300)
    end

    # it "should accept a file" do
    #   File.open('test_images/testimg.jpg') do |file|
    #     obj.image = file
    #     obj.original_meta.should include("mime_type"=>"image/jpeg", "geometry_x"=>200, "geometry_y"=>300)
    #   end
    # end

    context "with shot_at EXIF data" do
      before do
        obj.image = 'test_images/4s.jpg'
      end

      it "should set the shot_at value" do
        obj.shot_at.should_not be_nil
      end

      it "should be a time object" do
        obj.shot_at.should be_a Time
      end
    end

  end
end