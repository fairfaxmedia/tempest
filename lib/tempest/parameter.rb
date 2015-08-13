module Tempest
  class Parameter
    class Ref
      include Tempest::BaseRef
      RefClass = Tempest::Parameter
      RefType  = 'parameter'
      RefKey   = 'parameters'
    end

    attr_reader :name, :type, :opts

    def initialize(tmpl, name, type, opts = {})
      @tmpl = tmpl
      @name = name
      @type = type
      @opts = opts
    end

    def compile
      Hash.new.tap do |hash|
        hash['Type'] = Tempest::Util.mk_id(@type)
        @opts.each do |key, val|
          hash[Util.mk_id(key)] = Tempest::Util.compile(val)
        end
      end
    end
    alias :fragment_declare :compile

    def update(opts)
      @opts = @opts.merge(opts)
    end

    def fragment_ref
      { 'Ref' => @tmpl.fmt_name(@name) }
    end
  end
end
