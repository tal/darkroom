module Darkroom
  class NoImage < StandardError; end
  module Plugins::Sizing

    module ClassMethods

      def style name, style=nil
        style ||= name
        image_attributes[:styles][name] = style
        image_attributes[:styles]
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
            File.extname(file_name)[1..-1] # extname includes the dot
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

      private
      def style_image name
        if name == 'original'
          unless @original_image
            Rails.logger.error("re-uploading original image") # TODO: add specific info
          end
          original_image
        elsif style = image_attributes[:styles][name]
          if m = style.match(/(\d+)x(\d+)[#s]/)
            x = m[1].to_i
            y = m[2].to_i
            original_image.resize_to_fill(x, y)
          else
            original_image.change_geometry(style) do |cols, rows, _img|
              _img.resize(cols, rows)
            end
          end
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
