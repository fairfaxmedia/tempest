module Tempest
  module Util
    class Key
      def initialize(key)
        if key.is_a? String
          @key = key
        elsif key.is_a? Symbol
          @key = key.to_s.gsub(%r((^|_)\w)) {|ch| ch.delete('_').upcase }
        elsif key.is_a? Key
          @key = key.to_s
        else
          raise "Invalid key type: #{key.class}"
        end
      end

      def inspect
        "#<Key:#{@key}>"
      end

      def to_s
        @key
      end

      def +(other)
        other = Key.new(other) unless other.is_a?(Key)

        Key.new(self.to_s + other.to_s)
      end

      def eql?(other)
        other = Key.new(other) unless other.is_a?(Key)

        self.to_s == other.to_s
      end

      def hash
        @key.hash
      end
    end

    def self.key(name)
      return name if name.is_a?(Key)
      Key.new(name)
    end

    def self.mk_id(name)
      key(name).to_s
    end

    def self.compile(value, settings = {})
      case value
      when Hash
        compile_hash(value, method(__method__), settings)
      when Array
        compile_array(value, method(__method__), settings)
      when Symbol
        Key.new(value).to_s
      when Key
        value.to_s
      when Tempest::Setting
        unless settings.include?(value.key)
          raise Tempest::ReferenceMissing.new("Invalid setting #{value.key}")
        end
        compile(settings.fetch(value.key).value, settings)
      else
        if value.respond_to? :tempest_h
          compile(value.tempest_h, settings)
        elsif value.respond_to? :compile_reference
          value.compile_reference
        else
          value
        end
      end
    end

    def self.compile_declaration(value, settings = {})
      case value
      when Hash
        compile_hash(value, method(__method__), settings)
      when Array
        compile_array(value, method(__method__), settings)
      when Symbol
        mk_id(value)
      when Tempest::Setting
        unless settings.include?(value.key)
          raise Tempest::ReferenceMissing.new("Invalid setting #{value.key}")
        end
        compile(value.value, settings)
      else
        if value.respond_to? :tempest_h
          compile(value.tempest_h, settings)
        elsif value.respond_to? :compile_reference
          value.compile_declaration
        else
          value
        end
      end
    end

    private

    def self.compile_array(ary, continuation, settings = {})
      ary.map {|value| continuation[value, settings] }
    end

    def self.compile_hash(hash, continuation, settings = {})
      new_hash = Hash.new
      hash.each do |key, value|
        new_key = mk_id(key)
        new_value = continuation[value, settings]
        new_hash[new_key] = new_value
      end
      new_hash
    end
  end
end
