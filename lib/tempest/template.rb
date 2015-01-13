module Tempest
  class Template
    include Tempest

    attr_reader :parameters
    attr_reader :mappings
    attr_reader :resources
    attr_reader :conditions

    def initialize(&block)
      @resources   = {}
      @parameters  = {}
      @conditions  = {}
      @mappings    = {}
      @helpers     = {}
      @ids         = {}
      @factories   = {}

      instance_eval(&block) if block_given?
    end

    def description(desc)
      @description = desc
    end

    def helper(name, &block)
      @helpers[name] = block
    end

    def call(name, *args)
      @helpers[name].call(*args)
    end

    def [](id)
      res = @resources[id]
      par = @parameters[id]
      map = @parameters[id]

      found = [res, par, map].reject(&:nil?)
      if found.size > 1
        raise
      else
        found.first
      end
    end

    def resource(name)
      @resources[name] ||= Resource::Ref.new(self, name)
    end

    def substack(name)
      @resources[name] ||= Resource::SubStack.new(self, name)
    end

    def parameter(name)
      @parameters[name] ||= Parameter::Ref.new(self, name)
    end

    def inherit_parameter(name, parent)
      raise KeyError if @parameters.include? name
      @parameters[name] = Parameter::ChildRef.new(self, name, parent)
    end

    def mapping(name)
      @mappings[name] ||= Mapping::Ref.new(self, name)
    end

    def condition(name)
      @conditions[name] ||= Condition::Ref.new(self, name)
    end

    def factory(name)
      @factories[name] ||= Factory.new(self, name)
    end

    def to_h
      Hash.new.tap do |hash|
        hash['Description'] = @description unless @description.nil?

        resources = {}
        @resources.each do |name, res|
          resources[fmt_name(name)] = res.fragment_declare
        end

        unless @mappings.empty?
          hash['Mappings'] = Hash.new
          @mappings.each do |name, map|
            hash['Mappings'][fmt_name(name)] = map.fragment_declare
          end
        end
        unless @parameters.empty?
          hash['Parameters'] = Hash.new
          @parameters.each do |name, param|
            next unless param.referenced?
            hash['Parameters'][fmt_name(name)] = param.fragment_declare
          end
        end
        hash['Resources'] = resources
      end
    end

    def aws_region
      @aws_region ||= Builtin.new('AWS::Region')
    end

    def join(sep, *args)
      Function.new('Fn::Join', sep, args)
    end

    def fn_if(cond, t, f)
      Function.new('Fn::If', cond, t, f)
    end

    def default(value)
      DefaultParameter.new(self, value)
    end

    def self.fmt_name(name)
      Util.mk_id(name)
    end

    def fmt_name(name)
      Util.mk_id(name)
    end
  end
end
