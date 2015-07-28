require 'json'

module Tempest
  class Function
    include Tempest

    def initialize(name, *args)
      @name = name
      @args = args
    end

    def to_s
      JSON.generate(self.fragment_ref)
    end

    def fragment_ref
      { @name => Util.compile(@args) }
    end
  end
end
