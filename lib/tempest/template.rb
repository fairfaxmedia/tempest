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

      Hash.new.tap do |hash|
        hash['Description'] = @description unless @description.nil?

        # Resources and outputs are compiled first, since these are always
        # included. Anything that doesn't get referenced by a resource or
        # output won't be included in the output template.
        resources = {}
        @resources.each do |name, res|
          resources[name] = res.ref!
        end
        hash['Resources'] = compiler.compile(resources)

        unless @outputs.empty?
          outs = {}
          @outputs.each do |key, out|
            outs[key] = out.ref! if out.referenced?
          end
          hash['Outputs'] = Util.compile(outs)
        end

        cs = all_conditions.select {|k, v| compiler.seen?(v.ref_key) }
        ms = all_mappings.select   {|k, v| compiler.seen?(v.ref_key) }
        ps = all_parameters.select {|k, v| compiler.seen?(v.ref_key) }

        unless cs.empty?
          cs.keys.each do |k|
            cs[k] = cs.delete(k).ref!
          end
          hash['Conditions'] = compiler.compile(cs)
        end

        unless ms.empty?
          ms.keys.each do |k|
            ms[k] = ms.delete(k).ref!
          end
          hash['Mappings'] = compiler.compile(ms)
        end

        unless ps.empty?
          ps.keys.each do |k|
            ps[k] = ps.delete(k).ref!
          end
          hash['Parameters'] = compiler.compile(ps)
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
