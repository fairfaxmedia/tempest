module Tempest
  module BaseRef
    attr_reader :ref
    attr_reader :created_file, :created_line

    def initialize(template, name, parent = nil)
      @template   = template
      @name       = name
      @ref        = nil
      @referenced = false
      @parent     = nil
    end

    def referenced?
      @referenced
    end

    def child(id, opts = {})
      if id == @name
        raise DuplicateDefinition.new("Cannot create #{id} as a child of itself")
      end

      self.class.new(@template, id, self)
    end

    def with_prefix(prefix, opts = {})
      child(:"#{prefix}_#{@name}", opts)
    end

    def with_suffix(suffix, opts = {})
      child(:"#{@name}_#{suffix}", opts)
    end

    def compile_reference
      raise ref_missing unless created?

      @referenced = true

      { 'Ref' => Util.mk_id(@ref.name) }
    end

    def compile_definition
      raise ref_missing unless created?

      @ref.compile
    end

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

      @ref = RefClass.new(@template, @name, type, opts)
      self
    end

    def update(opts = {})
      if !@ref.nil?
        raise Tempest::DuplicateDefinition.new(
          "#{RefType.capitalize} #{@name} already been created at #{@created_file}:#{@created_line} - updates can only applied during inheritance"
        )
      elsif @parent.nil?
        raise TempestError.new("Cannot update #{RefType} without parent - updates can only be applied during inheritance")
      end

      file, line, _ = caller.first.split(':')
      @created_file = file
      @created_line = line

      @ref = RefClass.new(@template, @name, @parent.type, @parent.opts.merge(opts)
    end

    def created?
      @ref.nil? || (@parent && @parent.created?)
    end

    private

    def ref_missing
      Tempest::ReferenceMissing.new("#{RefType.capitalize} #{@name} has not been initialized")
    end

    def duplicate_definition
      Tempest::DuplicateDefinition.new("#{RefType.capitalize} #{@name} already been created at #{@created_file}:#{@created_line}")
    end
  end
end
