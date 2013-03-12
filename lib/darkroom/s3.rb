AWS::Core::Configuration.module_eval do
  add_option :s3_bucket, nil
  add_option :s3_acl, :public_read
end

module Darkroom::Plugins::S3
  class InvalidUploadPath < ArgumentError; end
  module ClassMethods
    def upload_path path=nil
      if m = /^(?:(.+?)@)?\/?(.+)$/.match(path)
        @__s3_bucket = nil
        image_attributes[:s3_bucket_name] = m[1]
        image_attributes[:upload_path] = m[2].sub(/^\/?/,'/')
      elsif path.nil?
        image_attributes[:upload_path]
      else
        raise InvalidUploadPath, 'must pass a uable string to ::upload_path'
      end
    end

    def s3_acl *args
      if args.empty?
        image_attributes[:s3_acl]||AWS.config.s3_acl
      else
        image_attributes[:s3_acl] = args.first
      end
    end

    def s3_bucket *args
      if args.empty?
        name = image_attributes[:s3_bucket_name] || AWS.config.s3_bucket
        return unless name.is_a?(String) || name.is_a?(Symbol)

        @__s3_bucket ||= begin
          name = name.to_s
          s3 = Darkroom::Plugins::S3.s3
          # TODO: Cache all s3 buckets
          # TODO: Create all buckets on load
          bucket = s3.buckets.find {|b| b.name == name}
          bucket ||= s3.buckets.create(name)
          bucket
        end

      else
        bucket = args.first
        if bucket.is_a?(Hash)
          bucket = bucket[Rails.env]
        end

        @__s3_bucket = nil
        image_attributes[:s3_bucket_name] = bucket
      end
    end

    def build_url args={}
      'http://'<<self.s3_bucket.name<<'.s3.amazonaws.com'<<build_path(opts)
    end
  end

  module InstanceMethods

    def original_image
      return @original_image if @original_image

      @original_image = if upload_info['original'].andand['uploaded_at']
        download_original_image
      end
    end

    def not_uploaded
      all_styles = ['original']+image_attributes[:styles].keys

      all_styles.select do |style|
        !upload_info[style].andand['uploaded_at']
      end
    end

    def upload what=:new
      to_upload = case what
      when Array
        what
      when :original
        ['original']
      when :all
        ['original']+image_attributes[:styles].keys
      when :new
        not_uploaded-['original']
      end

      to_upload.each do |name|
        upload_style name
      end

    end

    def download_original_image
      new_active_image(Magick::Image.from_blob(URL.new(s3_url(style: 'original')).get).first)
    end

    def s3_url opts={}
      'http://'<<self.class.s3_bucket.name<<'.s3.amazonaws.com'<<path(opts)
    end

    def s3_objs
      @s3_objs ||= Hash.new do |h, k|
        name = k.to_s
        h[name] = self.class.s3_bucket.objects[path(style: name).sub(/^\/?/,'')]
      end
    end

    def uploaded? style
      !!upload_info[style].andand['uploaded_at']
    end

    private

    def upload_style name
      upload_image name, style_image(name)
    end

    def upload_image name, img
      obj = s3_objs[name]

      reduced_redundancy = name.to_s != 'original'

      s3 = obj.write :data => img.to_blob,
                :acl => self.class.s3_acl,
                :reduced_redundancy => reduced_redundancy,
                :content_type => img.mime_type

      self.upload_info[name]||={}
      self.upload_info[name]['uploaded_at'] = Time.now

      s3
    end
  end

  def self.included(receiver)
    receiver.extend         ClassMethods
    receiver.send :include, InstanceMethods
  end

  def self.s3
    @s3 ||= AWS::S3.new
  end
end

