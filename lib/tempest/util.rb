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
        compile_hash(value)
      when Array
        compile_array(value)
      when Symbol
        mk_id(value)
      else
        if value.respond_to? :fragment_ref
          value.fragment_ref
        else
          value
        end
      end
    end

    private

    def self.compile_array(ary)
      ary.map {|value| compile(value) }
    end

    def self.compile_hash(hash)
      new_hash = Hash.new
      hash.each do |key, value|
        new_key = @tmpl.fmt_name(key)
        new_value = compile(value)
        new_hash[new_key] = new_value
      end
      new_hash
    end
  end
end
