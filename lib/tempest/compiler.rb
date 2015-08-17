require 'set'

module Tempest
  class Compiler
    def initialize(settings)
      @settings = settings
      @seen = Set.new
    end

    def compile(value)
      case value
      when Hash
        compile_hash(value)
      when Array
        compile_array(value)
      when Symbol
        Tempest::Util.key(value).to_s
      when Tempest::Util::Key
        value.to_s
      when Tempest::Setting
        unless @settings.include?(value.key)
          raise Tempest::ReferenceMissing.new("Invalid setting #{value.key}")
        end
        v = @settings.fetch(value.key).value
        if v.nil?
          raise Tempest::ReferenceMissing.new("Uninitialized setting #{value.key}")
        end
        compile(v)
      else
        if value.respond_to? :tempest_h
          @seen << value.ref_id if value.respond_to?(:ref_id)
          compile(value.tempest_h)
        else
          value
        end
      end
    end

    def seen?(obj)
      @seen.include? obj
    end

    private

    def compile_array(ary)
      ary.map {|value| compile(value) }
    end

    def compile_hash(hash)
      new_hash = Hash.new
      hash.each do |key, value|
        new_key = Tempest::Util.key(key).to_s
        new_value = compile(value)
        new_hash[new_key] = new_value
      end
      new_hash
    end
  end
end
