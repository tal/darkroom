require "darkroom/version"
require 'aws-sdk'
require 'rmagick'

module Darkroom
  module Plugins; end
end

%w{s3 sizing}.each do |f|
  require File.dirname(__FILE__)<<'/darkroom/'<<f
end

module Darkroom

  module ClassMethods
    attr_reader :image_attributes
  end
  
  module InstanceMethods
    def image= file
      filename = if file.respond_to? :original_filename
        file.original_filename
      else
        File.basename(file)
      end

      if file.respond_to? :tempfile
        file = file.tempfile.path
      end

      @original_image = Magick::Image.read(file).first

      if shot_at = @original_image.get_exif_by_entry('DateTimeOriginal').first[1]
        m = shot_at.match(/(\d{4}):(\d\d):(\d\d) (\d\d):(\d\d):(\d\d)/)
        self.shot_at = Time.utc(*[*m][1..-1]) if m
      end

      self.original_meta = {
        'mime_type' => @original_image.mime_type,
        'geometry_x' => @original_image.columns,
        'geometry_y' => @original_image.rows,
        'size' => @original_image.filesize,
        'name' => filename
      }

      @original_image
    end

    def image_attributes
      self.class.image_attributes
    end
  end

  def self.included(receiver)
    receiver.extend ClassMethods
    receiver.send :include, InstanceMethods
    receiver.instance_variable_set :@image_attributes, {}

    Darkroom::Plugins.constants.each do |plugin|
      plugin = Darkroom::Plugins.const_get(plugin)
      unless plugin.respond_to?(:should_include?) && !plugin.should_include?(receiver)
        receiver.send :include, plugin
      end
    end
  end
end
