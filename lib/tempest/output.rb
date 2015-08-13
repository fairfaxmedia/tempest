module Tempest
  class Output
    include Tempest

    class Ref
      include Tempest::BaseRef
      RefClass = Tempest::Output
      RefType  = "output"
      RefKey   = "outputs"
    end

    attr_accessor :name, :type, :tmpl

    def initialize(tmpl, name, value, opts = {})
      @name       = name
      @tmpl       = tmpl
      @value      = value

      @condition   = opts[:condition]   if opts.include? :condition
      @description = opts[:description] if opts.include? :description
    end

    def compile
      hash = { :value => @value }

      hash[:condition]   = @condition   if defined? @condition
      hash[:description] = @description if defined? @description

      Util.compile(hash)
    end
    alias :fragment_declare :compile

    def fragment_ref
      # FIXME
      raise 'Cannot reference an output'
    end

    def property(path, target)
      path = [path] unless path.is_a? Array
      name = path.pop
      root = @properties
      path.each do |dir|
        root[dir] ||= {}
        root = root[dir]
      end

      if target.respond_to? :construct
        target = target.construct(self, name)
      end

      root[name] = target

      # I think cloudformation works this out automatically
      # if target.respond_to? :depends_on
      #   @depends_on += target.depends_on
      # end
    end

    def properties(props, root = [])
      props.each do |key, target|
        if target.is_a? Hash
          properties(target, root+[key])
        else
          property(root+[key], target)
        end
      end
    end

    private

    def convert(value, key = nil)
      case value
      when Hash
        convert_hash(value)
      when Array
        convert_array(value)
      when Symbol
        Util.mk_id(value)
      else
        if value.respond_to? :fragment_ref
          value.fragment_ref
        else
          value
        end
      end
    end

    def convert_array(ary)
      ary.map.with_index {|value, i| convert(value, i) }
    end

    def convert_hash(hash)
      new_hash = Hash.new
      hash.each do |key, value|
        new_key = Util.mk_id(key)
        new_value = convert(value, key)
        new_hash[new_key] = new_value
      end
      new_hash
    end
  end
end
