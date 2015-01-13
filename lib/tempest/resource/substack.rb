module Tempest
  class SubStack < Resource::Ref
    include Tempest

    def create(properties)
      if properties.include? :template_url
        properties[:templateURL] = properties.delete(:template_url)
      end
      super('AWS::CloudFormation::Stack', properties)
    end

    def output(name)
      Function.new('Fn::GetAtt', self, "Outputs.#{Util.mk_id(name)}")
    end
  end
end
