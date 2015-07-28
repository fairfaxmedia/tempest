require 'json'

module Tempest
  class Template
    include Tempest

    attr_reader :parameters
    attr_reader :mappings
    attr_reader :resources
    attr_reader :conditions
    attr_reader :factories

    def initialize(&block)
      @libs        = []
      @resources   = {}
      @parameters  = {}
      @conditions  = {}
      @mappings    = {}
      @factories   = {}

      instance_eval(&block) if block_given?
    end

    def use(lib)
      @libs.push(lib)
    end

    def library(name)
      Library.catalog(name)
    end

    def description(desc)
      @description = desc
    end

    def resource(name)
      return @resources[name] if resources.include? name

      resource = @libs.reduce(nil) {|res, lib| res || lib.parameters[name] }

      @resources[name] = resource || Resource::Ref.new(self, name)
    end

    def parameter(name)
      return @parameters[name] if @parameters.include? name

      parameter = @libs.reduce(nil) {|param, lib| param || lib.parameters[name] }
      unless parameter.nil?
        parameter = parameter.dup.tap {|p| p.reparent(self) }
      end

      @parameters[name] = parameter || Parameter::Ref.new(self, name)
    end

    def inherit_parameter(name, parent)
      raise KeyError.new("Cannot create duplicate parameter #{name}") if @parameters.include? name
      @parameters[name] = Parameter::ChildRef.new(self, name, parent)
    end

    def mapping(name)
      return @mappings[name] if @mappings.include? name

      mapping = @libs.reduce(nil) {|map, lib| map || lib.mappings[name] }
      unless mapping.nil?
        mapping = mapping.dup.tap {|m| m.reparent(self) }
      end

      @mappings[name] = mapping || Mapping::Ref.new(self, name)
    end

    def condition(name)
      return @conditions[name] if @conditions.include? name

      condition = @libs.reduce(nil) {|cond, lib| cond || lib.conditions[name] }
      unless condition.nil?
        condition = condition.dup.tap {|c| c.reparent(self) }
      end

      @conditions[name] = condition || Condition::Ref.new(self, name)
    end

    def factory(name)
      return @factories[name] if @factories.include? name

      factory = @libs.reduce(nil) {|fact, lib| fact || lib.factories[name] }
      unless factory.nil?
        factory = factory.dup.tap {|f| f.reparent(self) }
      end

      @factories[name] = factory || Factory.new(self, name)
    end

    def to_h
      Hash.new.tap do |hash|
        hash['Description'] = @description unless @description.nil?

        resources = {}
        @resources.each do |name, res|
          resources[fmt_name(name)] = res.fragment_declare
        end

        unless @conditions.empty?
          hash['Conditions'] = Util.compile_declaration(@conditions)
        end

        unless @mappings.empty?
          hash['Mappings'] = Util.compile_declaration(@mappings)
        end

        ref_params = @parameters.select {|k,v| v.referenced? }
        unless ref_params.empty?
          hash['Parameters'] = Util.compile_declaration(ref_params)
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

    def no_value
      @no_value ||= Builtin.new('AWS::NoValue')
    end

    def cfn_id
      @cfn_id ||= Builtin.new('ID')
    end

    def cfn_stack_id
      @cfn_stack_id ||= Builtin.new('AWS::StackId')
    end

    def cfn_stack_name
      @cfn_stack_name ||= Builtin.new('AWS::StackName')
    end

    def join(sep, *args)
      Function.new('Fn::Join', sep, args)
    end

    def base64(data)
      Function.new('Fn::Join', data)
    end

    def fn_if(cond, t, f)
      Function.new('Fn::If', cond, t, f)
    end

    def fn_equals(x, y)
      Function.new('Fn::Equals', x, y)
    end

    def self.fmt_name(name)
      Util.mk_id(name)
    end

    def fmt_name(name)
      Util.mk_id(name)
    end
  end
end
