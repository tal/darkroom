module Darkroom
  class Thumbnail < Image
    attr_reader :geometry
    def initialize parent, geometry, format=nil
      @geometry = geometry
      @convert_to_format = format
      parent.instance_variables.each do |var|
        next if var == :@img
        instance_variable_set(var,parent.instance_variable_get(var))
      end

      @parent = parent

      @img = MiniMagick::Image.open(parent.img.path)

      process
    end

    def to_image
      Image.new(img.path)
    end

    def is_cropped?
      @is_cropped ||= geometry.match(/(?<x>\d+)x(?<y>\d+)[#s]/)
    end

    def inspect_opts
      opts = super
      opts << "geometry: #{geometry}"
      opts << 'processed' if @processed
      opts
    end

    private
    def process
      if match = is_cropped?
        resize_to_fill(match[:x],match[:y])
      else
        img.thumbnail(geometry)
      end

      img.format @convert_to_format if @convert_to_format

      @processed = true
    end

    def resize_to_fill ncols, nrows=nil
      nrows ||= ncols
      scale = [ncols.to_f/columns.to_f, nrows.to_f/rows.to_f].max
      return if scale == 1.0

      img.combine_options do |c|
        c.thumbnail "#{scale*columns+0.5}x#{scale*rows+0.5}"
        c.gravity "center"
        c.crop "#{ncols}x#{nrows}+0+0"
      end
    end
  end
end
