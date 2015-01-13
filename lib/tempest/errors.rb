module Tempest
  TempestError        = Class.new(StandardError)
  ReferenceMissing    = Class.new(TempestError)
  DuplicateDefinition = Class.new(TempestError)
end
