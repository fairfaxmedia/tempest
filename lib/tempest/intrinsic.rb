require 'json'

module Tempest
  class Builtin
    include Tempest

    def initialize(target)
      @target = target
    end

    def to_s
      JSON.generate(self.fragment_ref)
    end

    def fragment_ref
      { 'Ref' => @target }
    end
  end
end
