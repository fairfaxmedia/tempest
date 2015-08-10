module Tempest
  class Library
    include Tempest

    def self.catalog(name)
      @catalog ||= {}
      @catalog.fetch(name)
    end

    def self.add(name, lib)
      @catalog ||= {}
      @catalog[name] ||= lib
    end

    attr_reader :name
    attr_reader :parameters
    attr_reader :mappings
    attr_reader :resources
    attr_reader :conditions
    attr_reader :factories

    def initialize(name, &block)
      @name        = name
      @resources   = {}
      @parameters  = {}
      @conditions  = {}
      @mappings    = {}
      @factories   = {}
      @libraries   = []

      instance_eval(&block) if block_given?

      Tempest::Library.add(name, self)
    end

    def use(lib)
      @libraries.push(lib)
    end

    def library(name)
      Library.catalog(name)
    end

    def has_resource?(name)
      return true if @resources.include? name

      @libraries.any? {|lib| lib.has_resource?(name) }
    end

    def resource(name)
      return @resources[name] if @resources.include? name

      lib = @libraries.find {|lib| lib.has_resource?(name) }

      if lib.nil?
        @resources[name] = Resource::Ref.new(self, name)
      else
        @resources[name] = lib.resource(name)
      end
    end

    def has_parameter?(name)
      return true if @parameters.include? name

      @libraries.any? {|lib| lib.has_parameter?(name) }
    end

    def parameter(name)
      return @parameters[name] if @parameters.include? name

      lib = @libraries.find {|lib| lib.has_parameter?(name) }

      if lib.nil?
        @parameters[name] = Parameter::Ref.new(self, name)
      else
        @parameters[name] = lib.parameter(name)
      end
    end

    def inherit_parameter(name, parent)
      raise KeyError.new("Cannot create duplicate parameter #{name}") if @parameters.include? name
      @parameters[name] = Parameter::ChildRef.new(self, name, parent)
    end

    def has_mapping?(name)
      return true if @mappings.include? name

      @libraries.any? {|lib| lib.has_mapping?(name) }
    end

    def mapping(name)
      return @mappings[name] if @mappings.include? name

      lib = @libraries.find {|lib| lib.has_mapping?(name) }

      if lib.nil?
        @mappings[name] = Mapping::Ref.new(self, name)
      else
        @mappings[name] = lib.mapping(name)
      end
    end

    def has_condition?(name)
      return true if @conditions.include? name

      @libraries.any? {|lib| lib.has_condition?(name) }
    end

    def condition(name)
      return @conditions[name] if @conditions.include? name

      lib = @libraries.find {|lib| lib.has_condition?(name) }

      if lib.nil?
        @conditions[name] = Condition::Ref.new(self, name)
      else
        @conditions[name] = lib.condition(name)
      end
    end

    def has_factory?(name)
      return true if @factories.include? name

      @libraries.any? {|lib| lib.has_factory?(name) }
    end

    def factory(name)
      return @factories[name] if @factories.include? name

      lib = @libraries.find {|lib| lib.has_factory?(name) }

      if lib.nil?
        @factories[name] = Factory::Ref.new(self, name)
      else
        @factories[name] = lib.factory(name)
      end
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
