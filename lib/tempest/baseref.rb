module Tempest
  module BaseRef
    attr_reader :ref
    attr_reader :created_file, :created_line

    def initialize(template, name, parent = nil)
      @template   = template
      @name       = Util.key(name)
      @ref        = nil
      @referenced = false
      @parent     = parent
      @used_at    = []
    end

    def ref_id
      "#{type_name}:#{@name}"
    end

    def referenced?
      @referenced || (@parent && @parent.referenced?)
    end

    def child(id, opts = {})
      id = Util.key(id)
      if id == @name
        raise DuplicateDefinition.new("Cannot create #{id} as a child of itself")
      end

      new_child = @template.send(ref_key)[id] = self.class.new(@template, id, self)
      new_child.update(opts)
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

      { 'Ref' => Util.key(ref.name) }
    end

    def to_h
      raise ref_missing unless created?

      { 'Ref' => @name }
    end

    def tempest_h
      @referenced = true
      to_h
    end

    def compile_definition
      raise ref_missing unless created?

      ref.compile
    end
    alias :compile_declaration :compile_definition

    def type
      raise ref_missing unless created?

      ref.type
    end

    def opts
      raise ref_missing unless created?

      ref.opts
    end

    def create(*args, &block)
      file, line, _ = caller.first.split(':')

      raise duplicate_definition(caller.first) unless @ref.nil?

      @created_file = file
      @created_line = line

      @ref = ref_class.new(@template, @name, *args, &block)
      self
    end

    def update(*args)
      if !@ref.nil?
        raise Tempest::DuplicateDefinition.new(
          "#{type_name.capitalize} #{@name} already been created at #{@created_file}:#{@created_line} - updates can only applied during inheritance"
        )
      elsif @parent.nil?
        raise TempestError.new("Cannot update #{type_name} without parent - updates can only be applied during inheritance")
      end

      file, line, _ = caller.first.split(':')
      @created_file = file
      @created_line = line

      @ref = ref.dup
      @ref.update(*args)

      self
    end

    def created?
      !ref.nil?
    end

    def ref
      return @ref unless @ref.nil?

      @parent.nil? ? nil : @parent.ref
    end

    def ref!
      r = ref
      raise ref_missing if r.nil?
      r
    end

    def mark_used(pos)
      @used_at << pos.split(':').take(2).join(':')
      nil
    end

    private

    def type_name
      self.class.const_get(:RefType)
    end

    def ref_key
      self.class.const_get(:RefKey)
    end

    def ref_class
      self.class.const_get(:RefClass)
    end

    def ref_missing
      Tempest::ReferenceMissing.new("#{type_name.capitalize} #{@name} has not been initialized").tap do |err|
        err.referenced_from = @used_at
      end
    end

    def duplicate_definition(called_from)
      Tempest::DuplicateDefinition.new("#{type_name.capitalize} #{@name} already been created").tap do |err|
        err.declared   = "#{@created_file}:#{@created_line}"
        err.redeclared = called_from
      end
    end
  end
end
