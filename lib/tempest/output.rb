module Tempest
  class Output
    include Tempest

    class Ref
      def initialize(template, name)
        @template = template
        @name     = name
        @ref      = nil
      end

      def create(properties)
        raise duplicate_definition unless @ref.nil?

        @ref = Tempest::Output.new(@template, @name, type)
        @ref.properties(properties)
        self
      end

      def compile
        raise ref_missing if @ref.nil?
        @ref.compile
      end
      alias :fragment_ref :compile

      def compile_ref
        # FIXME
        raise 'Cannot reference an output'
      end
      alias :fragment_declare :compile_ref

      def att(*key)
        key = key.map {|k| Util.mk_id(k) }.join('.')
        Function.new('Fn::GetAtt', @name, key)
      end

      private

      def ref_missing
        Tempest::ReferenceMissing.new("Output #{@name} has not been initialized")
      end

      def duplicate_definition
        Tempest::DuplicateDefinition.new("Output #{@name} has already been created")
      end
    end

    attr_accessor :name, :type, :tmpl

    def initialize(tmpl, name, opts = {})
      @name       = name
      @tmpl       = tmpl

      @condition   = opts[:condition]   if opts.include? :condition
      @description = opts[:description] if opts.include? :description
    end

    def compile
      hash = { :value => @value }

      hash[:condition]   = @condition   if defined? @condition
      hash[:description] = @description if defined? @description

      hash
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
