module Tempest
  Error               = Class.new(StandardError)
  TempestError        = Error
  ReferenceMissing    = Class.new(TempestError)
  DuplicateDefinition = Class.new(TempestError)
end
