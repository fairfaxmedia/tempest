require 'tempest/condition'
require 'tempest/factory'
require 'tempest/mapping'
require 'tempest/output'
require 'tempest/parameter'
require 'tempest/resource'

module Tempest
  class Library
    include Tempest

    def self.catalog(name)
      @catalog ||= {}
      @catalog.fetch(name).tap(&:run!)
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
      @libraries   = []
      @helpers     = {}

      @conditions  = {}
      @factories   = {}
      @mappings    = {}
      @outputs     = {}
      @parameters  = {}
      @resources   = {}

      @block = block

      Tempest::Library.add(name, self)
    end

    def run!
      return if @run
      instance_eval(&@block)
      @run = true
    end

    def use(lib)
      @libraries.push(lib)
    end

    def library(name)
      Library.catalog(name)
    end

    keywords = [
      [:condition, :conditions, Tempest::Condition],
      [:factory,   :factories,  Tempest::Factory  ],
      [:mapping,   :mappings,   Tempest::Mapping  ],
      [:output,    :outputs,    Tempest::Output   ],
      [:parameter, :parameters, Tempest::Parameter],
      [:resource,  :resources,  Tempest::Resource ],
    ]

    # For each of the above, define #has_foo?(id) and #foo(id) methods,
    # e.g. has_resource?(id) and resource(id)
    keywords.each do |single, plural, klass|
      define_method(:"has_#{single}?") do |name|
        return true if instance_variable_get("@#{plural}").include?(name)

        instance_variable_get('@libraries').any? {|lib| lib.send(:"has_#{single}?", name) }
      end

      define_method(single) do |name|
        map = instance_variable_get("@#{plural}")
        return map[name] if map.include?(name)

        lib = instance_variable_get('@libraries').find {|lib| lib.send(:"has_#{single}?", name) }
        if lib.nil?
          map[name] = klass::Ref.new(self, name)
        else
          item = lib.send(single, name).dup
          item.reparent(self)
          map[name] = item
        end
      end
    end

    # It is possible to modify an inherited parameter.
    # e.g. parameter(:basic_default).spawn(:specific_param, :default => "foo")
    # will create a :specific_param parameter with a default value of "foo" and
    # other settings inherited from the basic_default parameter
    #
    # TODO: Implement this for other types too.
    def inherit_parameter(name, parent)
      if @parameters.include? name
        prev = @parameters[name]
        prev_file = prev.created_file
        prev_line = prev.created_line
        raise DuplicateDefinition.new("Parameter #{name} already created at #{prev_file} line #{prev_line}")
      end
      @parameters[name] = Parameter::ChildRef.new(self, name, parent)
    end

    def has_helper?(name)
      return true if @helpers.include?(name)

      @libraries.any? {|lib| lib.has_helper?(name) }
    end

    def helper(name, &block)
      if block_given?
        if @helpers.include?(name)
          raise DuplicateDefinition.new("Helper #{name} already defined here")
        end
        @helpers[name] = block
      else
        return @helpers[name] if @helpers.include?(name)

        lib = @libraries.find {|lib| lib.has_helper?(name) }
        if lib.nil?
          nil
        else
          lib.helper(name)
        end
      end
    end

    def method_missing(sym, *args)
      if has_helper?(sym)
        helper = helper(sym)
        helper.call(*args)
      end
    end

    # Various builtin values provided by cloudformation
    def builtin(id)
      case id
      when :account_id, 'AccountId'
        @account_id ||= Builtin.new('AWS::AccountId')
      when :notification_arns, 'NotificationARNs'
        @notif_arns ||= Builtin.new('AWS::NotificationARNs')
      when :region, 'Region'
        @region     ||= Builtin.new('AWS::Region')
      when :no_value, 'NoValue'
        @no_value   ||= Builtin.new('AWS::NoValue')
      when :stack_id, 'StackId'
        @stack_id   ||= Builtin.new('AWS::StackId')
      when :stack_name, 'StackName'
        @stack_name ||= Builtin.new('AWS::StackName')
      else
        raise ReferenceMissing.new("Invalid builtin #{id.inspect}")
      end
    end

    # Various functions provided by cloudformation
    # Some functions, like FindInMap are provided by the relevant type class
    # (i.e. Mapping), rather than accessed globally.
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
      when :get_azs
        Function::GetAZs
      else
        raise ReferenceMissing.new("Invalid function #{id.inspect}")
      end
    end
  end
end
