# Warning: horrendous metaprogramming abuse.
# I wanted to keep the dsl syntax as declarative as possible, and this allows
# me to use factory objects in a way that appears declarative.
module Tempest
  class Factory
    class Construct
      def initialize(scope, args = {})
        @scope = scope
        args.each do |name, value|
          define_singleton_method(name) { value }
        end
      end

      def method_missing(name, *args)
        if @scope.respond_to? name
          @scope.send(name, *args)
        else
          super
        end
      end

      def call(&block)
        instance_eval(&block)
      end
    end

    class Ref
      def initialize(template, name)
        @template = template
        @name     = name
      end

      def reparent(template)
        @template = template
      end

      def create(args = {}, &block)
        raise duplicate_definition unless @ref.nil?

        file, line, _ = caller.first.split(':')
        @created_file = file
        @created_line = line

        @ref = Tempest::Factory.new(@template, @name, args, &block)
        self
      end

      def construct(*args)
        raise ref_missing if @ref.nil?

        @ref.construct(*args)
      end

      private

      def ref_missing
        Tempest::ReferenceMissing.new("Factory #{@name} has not been initialized")
      end

      def duplicate_definition
        Tempest::DuplicateDefinition.new("Factory #{@name} already been created in #{@created_file} line #{@created_line}")
      end
    end

    def initialize(template, name, args = {}, &block)
      @template = template
      @name     = name
      @args     = args.keys # FIXME - values should be used for validation (and autoref?)
      @block    = block
    end

    def reparent(template)
      @template = template
    end

    # This is just for compatibility/consistency with how other elements are
    # created/declared
    def create(args = {}, &block)
    end

    def construct(*params)
      if @args.length != params.length
        raise ArgumentError.new("wrong number of arguments (#{params.length} for #{@args.length})")
      end
      Construct.new(@template, @args.zip(params)).call(&@block)
    end
  end
end
