require 'json'

module Tempest
  class Template
    include Tempest

    attr_reader :parameters
    attr_reader :mappings
    attr_reader :resources
    attr_reader :conditions

    def initialize(&block)
      @use         = []
      @resources   = {}
      @parameters  = {}
      @conditions  = {}
      @mappings    = {}
      @helpers     = {}
      @ids         = {}
      @factories   = {}

      instance_eval(&block) if block_given?
    end

    def use(template)
      @use.push(template)
    end

    def description(desc)
      @description = desc
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
      return @resources[name] if resources.include? name

      resource = @use.reduce(nil) {|res, lib| res || lib.parameters[name] }

      @resources[name] = resource || Resource::Ref.new(self, name)
    end

    def parameter(name)
      return @parameters[name] if @parameters.include? name

      parameter = @use.reduce(nil) {|param, lib| param || lib.parameters[name] }

      @parameters[name] = parameter || Parameter::Ref.new(self, name)
    end

    def inherit_parameter(name, parent)
      raise KeyError if @parameters.include? name
      @parameters[name] = Parameter::ChildRef.new(self, name, parent)
    end

    def mapping(name)
      return @mappings[name] if @mappings.include? name

      mapping = @use.reduce(nil) {|map, lib| map || lib.mappings[name] }

      @mappings[name] = mapping || Mapping::Ref.new(self, name)
    end

    def condition(name)
      return @conditions[name] if @conditions.include? name

      condition = @use.reduce(nil) {|cond, lib| cond || lib.conditions[name] }

      @conditions[name] = condition || Condition::Ref.new(self, name)
    end

    def factory(name)
      return @factories[name] if @factories.include? name

      facotry = @use.reduce(nil) {|fact, lib| fact || lib.factories[name] }

      @factories[name] = factory || Factory.new(self, name)
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

    def to_s
      JSON.generate(
        self.to_h,
        :indent    => '  ',
        :space     => ' ',
        :object_nl => "\n",
        :array_nl  => "\n",
      )
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
