require 'set'

module Util
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
        Key.new(value).to_s
      when Key
        value.to_s
      when Tempest::Setting
        unless @settings.include?(value.key)
          raise Tempest::ReferenceMissing.new("Invalid setting #{value.key}")
        end
        compile(@settings.fetch(value.key).value)
      else
        if value.respond_to? :tempest_h
          @seen << value.ref_key
          compile(value.tempest_h)
        elsif value.respond_to? :compile_reference
          @seen << value.ref_key
          value.compile_reference
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
      ary.map {|value| compile(value, settings) }
    end

    def compile_hash(hash)
      new_hash = Hash.new
      hash.each do |key, value|
        new_key = mk_id(key)
        new_value = compile(value, settings)
        new_hash[new_key] = new_value
      end
      new_hash
    end
  end
end
