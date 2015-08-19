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
        mandatory_sections = {
          'Resources' => all_resources,
          'Outputs'   => all_outputs,
        }
        mandatory_sections.each do |key, all_objects|
          map = {}
          all_objects.each do |obj_key, object|
            map[obj_key] = object.ref!
          end
          hash[key] = compiler.compile(map)
        end

        optional_sections = {
          'Conditions' => all_conditions,
          'Mappings'   => all_mappings,
          'Parameters' => all_parameters,
        }

        optional_sections.each do |key, all_objects|
          map = {}
          all_objects.each do |obj_key, object|
            next unless compiler.seen?(object.ref_id)
            map[obj_key] = object.ref!
          end
          hash[key] = compiler.compile(map)
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
