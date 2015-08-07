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

      def view(x)
        Tempest::Mapping::View.new(self, x)
      end

      def find(x, y)
        @referenced = true
        # This won't validate that the mapping is initialized, but in theory
        # the template should call #compile_ref which will catch the error
        Function::FindInMap.call(@name, x, y)
      end

      private

      def ref_missing
        Tempest::ReferenceMissing.new("Mapping #{@name} has not been initialized")
      end

      def duplicate_definition
        Tempest::DuplicateDefinition.new("Mapping #{@name} already created in #{@created_file} line #{@created_line}")
      end
    end

    def View
      def initialize(map, x)
        @map = map
        @x    = x
      end

      def find(y)
        @map.find(@x, y)
      end
    end

    def initialize(tmpl, name, body)
      @tmpl = tmpl
      @name = name
      depth_min, depth_max = hash_depth(body)
      if depth_min != 2 || depth_max != 2
        raise "#{name}: All Mapping branches must be 2 levels deep"
      end
      @body  = body
    end

    def fragment_declare
      Tempest::Util.compile(@body)
    end

    def fragment_ref
      raise "Cannot reference mapping directly. Use #find"
    end

    def find(x, y)
      Function::FindInMap.call(@name, x, y)
    end

    private

    def hash_depth(hash)
      min = 0
      max = 0

      hash.values.each do |v|
        if v.is_a? Hash
          v_min, v_max = hash_depth(v)
          min = v_min if v_min < min || min == 0
          max = v_max if v_min > max
        end
      end

      return min+1, max+1
    end
  end
end
