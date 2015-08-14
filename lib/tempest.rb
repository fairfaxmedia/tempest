module Tempest
  Setting = Struct.new(:key, :value)

  require 'tempest/errors'
  require 'tempest/util'

  require 'tempest/baseref'
  require 'tempest/library'
  require 'tempest/template'
  require 'tempest/mapping'
  require 'tempest/condition'
  require 'tempest/parameter'
  require 'tempest/resource'
  require 'tempest/intrinsic'
  require 'tempest/function'
  require 'tempest/factory'
end
