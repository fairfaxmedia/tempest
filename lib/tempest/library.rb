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
      @settings    = {}

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

    def set(pairs, &block)
      pairs.each do |key, value|
        if @settings.include?(key)
          s = @settings[key]
          raise DuplicateDefinition.new("Setting #{key} redeclared") if s.is_set?
          s.set(value)
        else
          @settings[key] = Setting.new(key, value, &block)
        end
      end
    end

    def setting(key)
      @settings[key] ||= Setting.new(key, settings[key])
    end

    def settings
      _settings = {}
      @libraries.each do |lib|
        _settings.merge!(lib.settings)
      end

      @settings.each do |k, v|
        if _settings.include? k
          v.set(_settings.fetch(k))
        else
          _settings[k] = v
        end
      end

      _settings
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
        name = Util.key(name)
        return true if instance_variable_get("@#{plural}").include?(name)

        instance_variable_get('@libraries').any? {|lib| lib.send(:"has_#{single}?", name) }
      end

      define_method(single) do |name|
        map = instance_variable_get("@#{plural}")
        name = Util.key(name)
        return map[name] if map.include?(name)

        called_from = caller.first

        lib = instance_variable_get('@libraries').find {|lib| lib.send(:"has_#{single}?", name) }
        if lib.nil?
          map[name] = klass::Ref.new(self, name)
        else
          item = lib.send(single, name)
          map[name] = klass::Ref.new(self, name, item)
        end

        map[name].tap {|ref| ref.mark_used(called_from) }
      end
    end

    def all_parameters
      _params = []
      @libraries.each do |lib|
        _params += lib.all_parameters
      end
      _params = (_params + @parameters.keys).uniq
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
      else
        super
      end
    end

    # Various builtin values provided by cloudformation
    def builtin(id)
      from = caller.first
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
        err = ReferenceMissing.new("Invalid builtin #{id.inspect}")
        err.referenced_from << from
        raise err
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
