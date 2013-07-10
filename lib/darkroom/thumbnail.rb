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

    private
    def process
      if match = is_cropped?
        resize_to_fill(match[:x],match[:y])
      else
        img.combine_options do |c|
          c.thumbnail(geometry)
          c.format @convert_to_format if @convert_to_format
        end
      end
    end

    # def resize_to_fill!(ncols, nrows=nil, gravity=CenterGravity)
    #     nrows ||= ncols
    #     if ncols != columns || nrows != rows
    #         scale = [ncols/columns.to_f, nrows/rows.to_f].max
    #         resize!(scale*columns+0.5, scale*rows+0.5)
    #     end
    #     crop!(gravity, ncols, nrows, true) if ncols != columns || nrows != rows
    #     self
    # end

    def resize_to_fill ncols, nrows=nil
      nrows ||= ncols
      scale = [ncols.to_f/columns.to_f, nrows.to_f/rows.to_f].max
      return if scale = 1.0

      img.combine_options do |c|
        c.thumbnail "#{scale*columns+0.5}x#{scale*rows+0.5}"
        c.gravity "center"
        c.crop "#{ncols}x#{nrows}+0+0"
        c.format @convert_to_format if @convert_to_format
      end
    end
  end
end
