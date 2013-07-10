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

      end

      private

      def style_image name
        if name == 'original'
          unless @original_image
            Rails.logger.error("re-uploading original image") # TODO: add specific info
          end
          original_image
        elsif style = image_attributes[:styles][name]
          @style_image ||= Hash.new do |h,k|
            h[k] = original_image.new_thumbnail k, image_attributes[:format]
          end
          @style_image[style]
        end
      end
    end

    def self.included(receiver)
      receiver.extend         ClassMethods
      receiver.send :include, InstanceMethods

      receiver.image_attributes[:styles] = {}
    end
  end
end
