module Tempest
  class Builtin
    include Tempest

    def initialize(target)
      @target = target
    end

    def fragment_ref
      { 'Ref' => @target }
    end
  end
end
