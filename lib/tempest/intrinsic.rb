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

    def to_h
      { 'Ref' => @target }
    end
    alias :tempest_h :to_h
  end
end
