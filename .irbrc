$:.unshift(File.expand_path('../lib',__FILE__))
require 'darkroom'
AWS.config(YAML.load_file(File.expand_path('../config/aws.yml',__FILE__)))