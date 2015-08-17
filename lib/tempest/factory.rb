# Warning: horrendous metaprogramming abuse.
# I wanted to keep the dsl syntax as declarative as possible, and this allows
# me to use factory objects in a way that appears declarative.
module Tempest
  class Factory
    class Ref
      include Tempest::BaseRef
      RefClass = Tempest::Factory
      RefType  = "factory"
      RefKey   = "factories"

      def construct(*args)
        ref!.construct(@template, *args)
      end

      def compile_definition
        raise "Cannot compile factories. Use #construct method"
      end

      def compile_reference
        raise "Cannot reference factories. Use #construct method"
      end
    end

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
        elsif @scope.has_helper?(name)
          @scope.helper(name).call(*args)
        else
          super
        end
      end

      def call(&block)
        instance_eval(&block)
      end
    end

    def initialize(template, name, args = {}, &block)
      @template = template # Unused - but part of the BaseRef #new call
      @name     = name
      @args     = args.keys # FIXME - values should be used for validation (and autoref?)
      @block    = block
    end

    def construct(template, *params)
      if @args.length != params.length
        raise ArgumentError.new("wrong number of arguments (#{params.length} for #{@args.length})")
      end
      Construct.new(template, @args.zip(params)).call(&@block)
    end
  end
end
