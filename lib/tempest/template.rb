require 'json'
require 'tempest/library'

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
      _settings = settings

      Hash.new.tap do |hash|
        hash['Description'] = @description unless @description.nil?

        # Resources and outputs are compiled first, since these are always
        # included. Anything that doesn't get referenced by a resource or
        # output won't be included in the output template.
        resources = {}
        @resources.each do |name, res|
          resources[name] = res.ref!
        end
        hash['Resources'] = Util.compile(resources, _settings)

        unless @outputs.empty?
          outs = {}
          @outputs.each do |key, out|
            outs[key] = out.ref! if out.referenced?
          end
          hash['Outputs'] = Util.compile(outs, _settings)
        end

        unless @conditions.empty?
          conds = {}
          @conditions.each do |key, cond|
            conds[key] = cond.ref! if cond.referenced?
          end
          hash['Conditions'] = Util.compile(conds, _settings)
        end

        unless @mappings.empty?
          mappings = {}
          @mappings.each do |key, m|
            mappings[key] = m.ref! if m.referenced?
          end
          hash['Mappings'] = Util.compile(mappings, _settings)
        end

        unless all_parameters.empty?
          params = {}
          all_parameters.each do |key|
            p = parameter(key)
            params[key] = p.ref! if p.referenced?
          end
          hash['Parameters'] = Util.compile(params, _settings)
        end
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
