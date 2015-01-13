module Tempest
  class Function
    include Tempest

    def initialize(name, *args)
      @name = name
      @args = args
    end

    def fragment_ref
      { @name => Util.compile(@args) }
    end
  end
end
