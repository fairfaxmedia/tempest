module Tempest
  class Output
    include Tempest

    class Ref
      include Tempest::BaseRef
      RefClass = Tempest::Output
      RefType  = "output"
      RefKey   = "outputs"
    end

    attr_accessor :name, :type, :tmpl

    def initialize(tmpl, name, value, opts = {})
      @name       = name
      @tmpl       = tmpl
      @value      = value

      @condition   = opts[:condition]   if opts.include? :condition
      @description = opts[:description] if opts.include? :description
    end

    def compile
      hash = { :value => @value }

      hash[:condition]   = @condition   if defined? @condition
      hash[:description] = @description if defined? @description

      Util.compile(hash)
    end
    alias :fragment_declare :compile

    def to_h
      hash = { :value => @value }

      hash[:condition]   = @condition   if defined? @condition
      hash[:description] = @description if defined? @description

      hash
    end
    alias :tempest_h :to_h

    def fragment_ref
      # FIXME
      raise 'Cannot reference an output'
    end
  end
end
