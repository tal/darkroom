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
          "#{url.domain}.#{format}"
        else
          if file.respond_to? :original_filename
            file.original_filename
          else
            File.basename(file)
          end
        end

        file_info['name'] = @filename
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

    def path
      img.path
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
      file_info['geometry_x']
    end
    alias columns width

    def height
      file_info['geometry_y']
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
        @width = @width.to_i
        @height = @height.to_i
        @format = @format.downcase
        @shot_at = Time.utc(*shot_at.split(/:|\s+/)) rescue nil
        {
            'format' => @format,
         'mime_type' => "image/#{@format}",
        'geometry_x' => @width,
        'geometry_y' => @height,
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
