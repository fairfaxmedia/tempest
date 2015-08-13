module Tempest
  module Util
    def self.mk_id(name)
      case name
      when Symbol
        name.to_s.gsub(%r((^|_)\w)) {|ch| ch.delete('_').upcase }
      else
        name
      end
    end

    def self.compile(value)
      case value
      when Hash
        compile_hash(value, method(__method__))
      when Array
        compile_array(value, method(__method__))
      when Symbol
        mk_id(value)
      else
        if value.respond_to? :compile_reference
          value.compile_reference
        else
          value
        end
      end
    end

    def self.compile_declaration(value)
      case value
      when Hash
        compile_hash(value, method(__method__))
      when Array
        compile_array(value, method(__method__))
      when Symbol
        mk_id(value)
      else
        if value.respond_to? :compile_declaration
          value.compile_declaration
        else
          value
        end
      end
    end

    private

    def self.compile_array(ary, continuation)
      ary.map {|value| continuation[value] }
    end

    def self.compile_hash(hash, continuation)
      new_hash = Hash.new
      hash.each do |key, value|
        new_key = mk_id(key)
        new_value = continuation[value]
        new_hash[new_key] = new_value
      end
      new_hash
    end
  end
end
