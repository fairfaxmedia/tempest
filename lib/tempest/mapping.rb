module Tempest
  class Mapping
    class Ref
      attr_reader :ref
      attr_reader :created_file, :created_line

      def initialize(template, name)
        @template   = template
        @name       = name
        @ref        = nil
        @referenced = true
      end

      def reparent(template)
        @template = template
      end

      def referenced?
        @referenced
      end

      def create(body)
        raise duplicate_definition unless @ref.nil?

        file, line, _ = caller.first.split(':')
        @created_file = file
        @created_line = line

        @ref = Tempest::Mapping.new(@template, @name, body)
      end

      def compile
        raise Tempest::Error.new("Cannot reference a Mapping directly. Use #find")
      end
      alias :fragment_ref :compile

      def compile_ref
        raise ref_missing if @ref.nil?
        @ref.fragment_declare
      end
      alias :fragment_declare :compile_ref

      def find(*path)
        @referenced = true
        # This won't validate that the mapping is initialized, but in theory
        # the template should call #compile_ref which will catch the error
        Function.new('Fn::FindInMap', @name, *path)
      end

      private

      def ref_missing
        Tempest::ReferenceMissing.new("Mapping #{@name} has not been initialized")
      end

      def duplicate_definition
        Tempest::DuplicateDefinition.new("Mapping #{@name} already created in #{@created_file} line #{@created_line}")
      end
    end

    def initialize(tmpl, name, body)
      @tmpl = tmpl
      @name = name
      @body = body
    end

    def fragment_declare
      @body
    end

    def fragment_ref
      raise "Cannot reference mapping directly. Use #find"
    end

    def find(*path)
      Function.new('Fn::FindInMap', @name, *path)
    end
  end
end
