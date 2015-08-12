require 'json'
require 'tempest/library'

module Tempest
  class Template < Tempest::Library
    attr_reader :description

    def initialize(&block)
      @libraries   = []
      @resources   = {}
      @parameters  = {}
      @conditions  = {}
      @mappings    = {}
      @factories   = {}

      instance_eval(&block) if block_given?
    end

    def description(desc)
      @description = desc
    end

    def to_h
      Hash.new.tap do |hash|
        hash['Description'] = @description unless @description.nil?

        resources = {}
        @resources.each do |name, res|
          resources[Util.mk_id(name)] = res.fragment_declare
        end

        output = {}
        @outputs.each do |name, out|
          outputs[Util.mk_id(name)] = out.compile
        end

        conds = @conditions.select {|k,v| v.referenced? }
        hash['Conditions'] = Util.compile_declaration(conds) unless conds.empty?

        maps = @mappings.select {|k,v| v.referenced? }
        hash['Mappings'] = Util.compile_declaration(maps) unless maps.empty?

        hash['Outputs'] = outputs unless @outputs.empty?

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
  end
end
