module Tempest
  class Condition
    class Ref
      attr_reader :ref

      def initialize(template, name)
        @template   = template
        @name       = name
        @ref        = nil
        @referenced = false
      end

      def referenced?
        @referenced
      end

      def create(body)
        @ref = Tempest::Condition.new(@template, @name, body)
      end

      def created?
        !@ref.nil?
      end

      def compile
        raise Tempest::Error.new("Cannot reference a Condition directly. Use #if")
      end
      alias :fragment_ref :compile

      def compile_ref
        raise ref_missing if @ref.nil?
        @ref.fragment_declare
      end
      alias :fragment_declare :compile_ref

      def if(t, f)
        @referenced = true
        Function.new('Fn::If', @name, t, f)
      end

      private

      def ref_missing
        Tempest::ReferenceMissing.new("Condition #{@name} has not been initialized")
      end
    end

    def initialize(tmpl, name, body)
      @tmpl = tmpl
      @name = name
      @body = body
    end

    def fragment_declare
      Tempest::Util.compile(@body)
    end

    def fragment_ref
      raise Tempest::Error.new("Cannot reference condition directly. Use #if")
    end

    def if(t, f)
      Function.new('Fn::If', @name, t ,f)
    end
  end
end
