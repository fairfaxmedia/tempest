require 'json'
require 'tempest/library'
require 'tempest/compiler'

module Tempest
  class Template < Tempest::Library
    attr_reader :description

    def initialize(&block)
      @libraries   = []
      @helpers     = {}
      @settings    = {}

      @conditions  = {}
      @factories   = {}
      @mappings    = {}
      @outputs     = {}
      @parameters  = {}
      @resources   = {}

      instance_eval(&block) if block_given?
    end

    def description(desc)
      @description = desc
    end

    def to_h
      compiler = Tempest::Compiler.new(settings)

      resource_keys  = all_resources.keys
      parameter_keys = all_parameters.keys

      conflicts = resource_keys & parameter_keys
      unless conflicts.empty?
        # TODO - Create a meta-error that contains many cases?
        key = conflicts.first
        err = DuplicateDefinition.new("#{key} used as both a resource and a parameter")
      end

      Hash.new.tap do |hash|
        hash['Description'] = @description unless @description.nil?

        # Resources and outputs are compiled first, since these are always
        # included. Anything that doesn't get referenced by a resource or
        # output won't be included in the output template.
        resources = {}
        all_resources.each do |name, res|
          resources[name] = res.ref!
        end
        hash['Resources'] = compiler.compile(resources)

        outputs = {}
        all_outputs.each do |name, out|
          outputs[name] = out.ref!
        end
        hash['Outputs'] = compiler.compile(outputs)

        hash['Conditions'] = {}
        all_conditions.each do |key, value|
          next unless compiler.seen?(value.ref_id)

          hash['Conditions'][key] = compiler.compile(value.ref!)
        end
        hash

        hash['Mappings'] = {}
        maps = all_mappings
        unless maps.empty?
          maps.each do |key, value|
            next unless compiler.seen?(value.ref_id)

            maps[key] = compiler.compile(value.ref!)
          end
          hash['Mappings'] = compiler.compile(maps)
        end

        hash['Parameters'] = {}
        all_parameters.each do |key, value|
          next unless compiler.seen?(value.ref_id)

          hash['Parameters'][key] = compiler.compile(value.ref!)
        end

        hash.delete_if {|key, value| value.empty? }

        hash
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
  end
end
