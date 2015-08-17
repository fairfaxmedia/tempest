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

    def ref_id
      "parameter:#{@name}"
    end

    def compile
      Hash.new.tap do |hash|
        hash['Type'] = Tempest::Util.key(@type)
        @opts.each do |key, val|
          hash[Util.key(key)] = Tempest::Util.compile(val)
        end
      end
    end
    alias :fragment_declare :compile

    def to_h
      Hash.new.tap do |hash|
        hash['Type'] = @type
        @opts.each do |key, val|
          hash[key] = val
        end
      end
    end
    alias :tempest_h :to_h

    def update(opts)
      @opts = @opts.merge(opts)
    end

    def fragment_ref
      { 'Ref' => @tmpl.fmt_name(@name) }
    end
  end
end
