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

  def Library(name, &block)
    @libraries ||= {}
    @libraries[name] ||= Tempest::Library.new
    if block_given?
      @libraries[name].instance_eval(block)
    end
    @libraries[name]
  end
end
