module Tempest
  Error               = Class.new(StandardError)
  TempestError        = Error
  ReferenceMissing    = Class.new(TempestError)

  class DuplicateDefinition < Error
    attr_accessor :declared
    attr_accessor :redeclared

  end

  class ReferenceMissing < Error
    attr_accessor :referenced_from

    def initialize(*args, &block)
      @referenced_from = []
      super
    end
  end
end
