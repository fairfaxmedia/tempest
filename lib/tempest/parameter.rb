module Tempest
  class Parameter
    class Ref
      attr_reader :ref
      attr_reader :created_file, :created_line

      def initialize(template, name)
        @template   = template
        @name       = name
        @ref        = nil
        @referenced = false
      end

      def reparent(template)
        @template = template
      end

      def referenced?
        @referenced
      end

      def spawn(id, opts = {})
        @template.inherit_parameter(id, self).create(opts)
      end

      def with_prefix(prefix, opts = {})
        spawn(:"#{prefix}_#{@name}", opts)
      end

      def with_suffix(suffix, opts = {})
        spawn(:"#{@name}_#{suffix}", opts)
      end

      def compile
        raise ref_missing if @ref.nil?

        @referenced = true

        { 'Ref' => Util.mk_id(@ref.name) }
      end
      alias :fragment_ref :compile

      def compile_ref
        raise ref_missing if @ref.nil?

        @ref.compile
      end
      alias :fragment_declare :compile_ref

      def type
        raise ref_missing if @ref.nil?

        @ref.type
      end

      def opts
        raise ref_missing if @ref.nil?

        @ref.opts
      end

      def create(type, opts = {})
        raise duplicate_definition unless @ref.nil?

        file, line, _ = caller.first.split(':')
        @created_file = file
        @created_line = line

        @ref = Tempest::Parameter.new(@template, @name, type, opts)
        self
      end

      def default?
        cond = @template.condition(:"#{@name}_default")
        cond.create(@ref.mk_eq_default) unless cond.created?
        cond
      end

      def if_default(t, f = self)
        default?.if(t, f)
      end

      private

      def ref_missing
        Tempest::ReferenceMissing.new("Parameter #{@name} has not been initialized")
      end

      def duplicate_definition
        Tempest::DuplicateDefinition.new("Parameter #{@name} already been created in #{@created_file} line #{@created_line}")
      end
    end

    class ChildRef < Ref
      def initialize(template, name, parent)
        @parent = parent
        super(template, name)
      end

      def create(opts = {})
        super(@parent.type, @parent.opts.merge(opts))
      end
    end

    attr_reader :name, :type, :opts

    def initialize(tmpl, name, type, opts = {})
      @tmpl = tmpl
      @name = name
      @type = type
      @opts = opts
    end

    def compile
      Hash.new.tap do |hash|
        hash['Type'] = Tempest::Util.mk_id(@type)
        @opts.each do |key, val|
          hash[Util.mk_id(key)] = Tempest::Util.compile(val)
        end
      end
    end
    alias :fragment_declare :compile

    def fragment_ref
      { 'Ref' => @tmpl.fmt_name(@name) }
    end
  end
end
