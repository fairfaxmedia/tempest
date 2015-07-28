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

    def initialize(template, name)
      @template = template
      @name     = name
    end

    def reparent(template)
      @template = template
    end

    # This is just for compatibility/consistency with how other elements are
    # created/declared
    def create(args = {}, &block)
      @args  = args.keys # FIXME - values should be used for validation (and autoref?)
      @block = block
    end

    def construct(*params)
      if @args.length != params.length
        raise ArgumentError.new("wrong number of arguments (#{params.length} for #{@args.length})")
      end
      Construct.new(@template, @args.zip(params)).call(&@block)
    end
  end
end
