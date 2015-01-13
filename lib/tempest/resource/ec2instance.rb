module Tempest
  class EC2Instance < Resource
    include Tempest

    def initialize(tmpl, name, options = {})
      super(tmpl, name, 'AWS::EC2::Instance')
    end

    def create_volume(name = nil)
    end
  end
end
