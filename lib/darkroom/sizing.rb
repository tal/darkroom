module Darkroom
  class NoImage < StandardError; end
  module Plugins::Sizing

    module ClassMethods

      def style name, style=nil
        style ||= name
        image_attributes[:styles][name] = style
        image_attributes[:styles]
      end

      def format name
        image_attributes[:format] = name
      end

      def build_path args={}
        image_attributes[:upload_path].gsub(/(?::(\w+))/) do |key|
          args[$1]||args[$1.to_sym]||key
        end
      end

    end

    module InstanceMethods

      def path args = {}
        raise NoImage unless image?
        file_name = original_meta['name']
        image_attributes[:upload_path].gsub(/(?::(\w+))/) do |key|
          case $1
          when 'extension'
            if image_attributes[:format]
              image_attributes[:format]
            else
              File.extname(file_name)[1..-1] # extname includes the dot
            end
          when 'base'
            File.basename(file_name).sub(File.extname(file_name),'')
          when 'filename'
            File.basename(file_name)
          else
            begin
              args[$1]||args[$1.to_sym]||__send__($1)
            rescue NoMethodError
              key
            end
          end
        end
      end

      def styles
        upload_info.keys
      end

      def cleanup_active_images
        active_images.each {|img| img.destroy!}
      end

      private

      def style_image name
        if name == 'original'
          unless @original_image
            Rails.logger.error("re-uploading original image") # TODO: add specific info
          end
          img = original_image
        elsif style = image_attributes[:styles][name]
          if m = style.match(/(\d+)x(\d+)[#s]/)
            x = m[1].to_i
            y = m[2].to_i
            img = original_image.resize_to_fill(x, y)
          else
            img = original_image.change_geometry(style) do |cols, rows, _img|
              _img.resize(cols, rows)
            end
          end

          img.format = image_attributes[:format] if image_attributes[:format]
        end

        new_active_image(img)
      end

      def new_active_image img
        active_images << img
        img
      end

      def active_images
        @active_images ||=[]
      end
    end

    def self.included(receiver)
      receiver.extend         ClassMethods
      receiver.send :include, InstanceMethods

      receiver.image_attributes[:styles] = {}
    end
  end
end
