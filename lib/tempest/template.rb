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

      lib = @libs.find {|lib| lib.has_parameter?(name) }

      if lib.nil?
        @parameters[name] = Parameter::Ref.new(self, name)
      else
        @parameters[name] = lib.parameter(name)
      end

      @parameters[name]
    end

    def inherit_parameter(name, parent)
      raise KeyError.new("Cannot create duplicate parameter #{name}") if @parameters.include? name
      @parameters[name] = Parameter::ChildRef.new(self, name, parent)
    end

    def mapping(name)
      return @mappings[name] if @mappings.include? name

      lib = @libs.find {|lib| lib.has_mapping?(name) }

      if lib.nil?
        @mappings[name] = Mapping::Ref.new(self, name)
      else
        @mappings[name] = lib.mapping(name)
      end

      @mappings[name]
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
          resources[Util.mk_id(name)] = res.fragment_declare
        end

        conds = @conditions.select {|k,v| v.referenced? }
        hash['Conditions'] = Util.compile_declaration(conds) unless conds.empty?

        maps = @mappings.select {|k,v| v.referenced? }
        hash['Mappings'] = Util.compile_declaration(maps) unless maps.empty?

        params = @parameters.select {|k,v| v.referenced? }
        hash['Parameters'] = Util.compile_declaration(params) unless params.empty?

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

    def builtin(id)
      case id
      when :account_id
        @account_id ||= Builtin.new('AWS::AccountId')
      when :notification_arns
        @notif_arns ||= Builtin.new('AWS::NotificationARNs')
      when :region
        @region ||= Builtin.new('AWS::Region')
      when :no_value
        @no_value ||= Builtin.new('AWS::NoValue')
      when :stack_id
        @stack_id ||= Builtin.new('AWS::StackId')
      when :stack_name
        @stack_name ||= Builtin.new('AWS::StackName')
      else
        raise "Invalid builtin #{id.inspect}"
      end
    end

    def function(id)
      case id
      when :base64
        Function::Base64
      when :join
        Function::Join
      when :if
        Function::If
      when :equals
        Function::Equals
      else
        raise "Invalid function #{id.inspect}"
      end
    end
  end
end
