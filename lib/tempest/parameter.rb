module Tempest
  class Parameter
    class Ref
      attr_reader :ref
      attr_reader :created_file, :created_line

      def initialize(template, name, parent = nil)
        @template   = template
        @name       = name
        @ref        = nil
        @referenced = false
        @parent     = nil
      end

      def reparent(template)
        # TODO - Deprecated. Refs should refer to parent refs, not be duplicated/reparents
        @template = template
      end

      def referenced?
        @referenced
      end

      def child(id, opts = {})
        if id == @name
          raise DuplicateDefinition.new("Cannot create #{id} as a child of itself")
        end

        Parameter::Ref.new(@template, id, self)
      end

      def with_prefix(prefix, opts = {})
        child(:"#{prefix}_#{@name}", opts)
      end

      def with_suffix(suffix, opts = {})
        child(:"#{@name}_#{suffix}", opts)
      end

      def compile
        raise ref_missing unless created?

        @referenced = true

        { 'Ref' => Util.mk_id(@ref.name) }
      end
      alias :fragment_ref :compile
      alias :compile_reference :compile

      def compile_ref
        raise ref_missing unless created?

        @ref.compile
      end
      alias :fragment_declare :compile_ref
      alias :compile_declaration :compile_ref

      def type
        raise ref_missing unless created?

        @ref.type
      end

      def opts
        raise ref_missing unless created?

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

      def update(opts = {})
        if !@ref.nil?
          raise Tempest::DuplicateDefinition.new(
            "Parameter #{@name} already been created at #{@created_file}:#{@created_line} - updates can only applied during inheritance"
          )
        elsif @parent.nil?
          raise TempestError.new("Cannot update parameter without parent")
        end

        file, line, _ = caller.first.split(':')
        @created_file = file
        @created_line = line

        @ref = Tempest::Parameter.new(@template, @name, @parent.type, @parent.opts.merge(opts)
      end

      def created?
        @ref.nil? || (@parent && @parent.created?)
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
      def create(opts = {})
        super(@parent.type, @parent.opts.merge(opts))
      end

      def compile_ref
        create if @ref.nil? && created?

        super
      end

      private

      def created?
        @ref.nil? || @parent.created?
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
