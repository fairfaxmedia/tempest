module Tempest
  class Condition
    class Ref
      include Tempest::BaseRef
      RefClass = Tempest::Condition
      RefType  = 'parameter'
      RefKey   = 'parameters'

      def tempest_h
        raise Tempest::Error.new("Cannot reference a Condition directly. Use #if")
      end

      def equals(x, y)
        create(Function::Equals.call(x, y))
      end

      def if(t, f)
        @referenced = true
        Function::If.call(@name, t, f)
      end
    end

    def initialize(tmpl, name, body)
      @tmpl = tmpl
      @name = name
      @body = body
    end

    def ref_id
      "condition:#{@name}"
    end

    def compile_definition
      Tempest::Util.compile(@body)
    end
    alias :compile_declaration :compile_definition

    def to_h
      @body
    end
    alias :tempest_h :to_h

    def if(t, f)
      Function::If.call(@name, t, f)
    end
  end
end
