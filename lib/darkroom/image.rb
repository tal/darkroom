module Darkroom
  class Image
    attr_reader :img, :filename,:thumbnails
    def initialize file, processed_file_info=nil
      @thumbnails = []
      @img = MiniMagick::Image.open(file)

      if processed_file_info
        self.file_info = processed_file_info
      else
        @img.auto_orient
        file_info

        @filename = if file.is_a? String and file =~ /^https?:\/\//
          url = URL.new(file)
          "#{url.domain}.#{@original_image.mime_type[/\/(.+)/,1]}"
        else
          if file.respond_to? :original_filename
            file.original_filename
          else
            File.basename(file)
          end
        end
      end
    end

    def dup
      new_obj = self.class.allocate

      instance_variables.each do |var|
        next if var == :@img
        new_obj.instance_variable_set(var,instance_variable_get(var))
      end

      new_img = MiniMagick::Image.open(img.path)
      new_obj.instance_variable_set(:@img,new_img)
      new_obj
    end

    def to_blob
      img.to_blob
    end

    def new_thumbnail *args
      t = Thumbnail.new(self,*args)
      @thumbnails << t
      t
    end

    def width
      file_info['width']
    end
    alias columns width

    def height
      file_info['height']
    end
    alias rows height

    def filesize
      img[:size]
    end

    def shot_at
      file_info['shot_at']
    end
    alias original_at shot_at

    def format
      file_info['format']
    end

    def mime_type
      "image/#{format}"
    end

    def file_info
      @info ||= begin
        raw = img["%m|%w|%h|%[EXIF:DateTimeOriginal]"]
        @format,@width,@height,shot_at = raw.split('|')
        @format = @format.downcase
        @shot_at = Time.utc(*shot_at.split(/:|\s+/)) rescue nil
        {
            'format' => @format,
             'width' => @width,
            'height' => @height,
           'shot_at' => @shot_at,
              'name' => @filename,
              'size' => filesize
        }
      end
    end

    def file_info= data
      @format = data['format']
      @width = data['width']
      @height = data['height']
      @shot_at = data['shot_at']
      @filename = data['filename']
      @info = data
    end

    def aspect_ratio
      width.to_f/height.to_f
    end
  end
end
