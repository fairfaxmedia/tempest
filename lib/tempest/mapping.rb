module Tempest
  class Mapping
    class Ref
      include Tempest::BaseRef
      RefClass = Tempest::Mapping
      RefType  = "mapping"
      RefKey   = "mappings"

      def tempest_h
        @name
      end

      def find(x, y)
        Function::FindInMap.call(self, x, y)
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

    def ref_id
      "mapping:#{@name}"
    end

    def compile
      Tempest::Util.compile(@body)
    end

    def to_h
      @body
    end
    alias :tempest_h :to_h

    def update(opts)
      body = @body.merge(opts)
      depth_min, depth_max = hash_depth(body)
      if depth_min != 2 || depth_max != 2
        raise "#{name}: All Mapping branches must be 2 levels deep"
      end
      @body = body
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
