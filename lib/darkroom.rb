require "darkroom/version"
require 'aws-sdk'
require 'RMagick'
require 'mini_magick'
require 'open-uri'
require 'url'

module Darkroom
  module Plugins; end
end

%w{s3 sizing image sizing}.each do |f|
  require File.dirname(__FILE__)<<'/darkroom/'<<f
end

module Darkroom

  module ClassMethods
    attr_reader :image_attributes
  end

  module InstanceMethods

    def image?
      !original_meta.empty? if original_meta
    end

    def image_changed?
      @image_set
    end

    def image= file
      if file.respond_to? :tempfile
        file = file.tempfile.path
      end

      @original_image = Image.new(file)

      @image_set = true

      self.original_meta = @original_image.file_info
      self.shot_at = @original_image.shot_at

      @original_image
    end

    def image_size_ratio
      return unless original_meta && (y = original_meta['geometry_y']) && (x = original_meta['geometry_x'])

      x.to_f/y.to_f
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
