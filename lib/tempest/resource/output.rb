module Tempest
  class Resource
    class Output
      def initialize(res, name)
        @res  = res
        @name = name
      end

      def fragment_ref
        Function.new('Fn::GetAtt', @res.name, @name).fragment_ref
      end

      def depends_on
        [@res.name]
      end
    end
  end
end
