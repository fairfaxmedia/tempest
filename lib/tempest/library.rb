module Tempest
  class Library
    include Tempest

    def self.catalog(name)
      @catalog ||= {}
      @catalog.fetch(name)
    end

    def self.add(name, &block)
      @catalog ||= {}
      @catalog[name] ||= Library.new
      @catalog[name].instance_eval(&block)
    end

    attr_reader :parameters
    attr_reader :mappings
    attr_reader :resources
    attr_reader :conditions
    attr_reader :factories

    def initialize
      @resources   = {}
      @parameters  = {}
      @conditions  = {}
      @mappings    = {}
      @factories   = {}
    end

    def resource(name)
      @resources[name] ||= Resource::Ref.new(self, name)
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

    def aws_region
      @aws_region ||= Builtin.new('AWS::Region')
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

    def fn_if(cond, t, f)
      Function.new('Fn::If', cond, t, f)
    end

    def fn_equals(x, y)
      Function.new('Fn::Equals', x, y)
    end
  end

  def Library(name, &block)
    @libraries ||= {}
    @libraries[name] ||= Tempest::Library.new
    if block_given?
      @libraries[name].instance_eval(block)
    end
    @libraries[name]
  end
end
