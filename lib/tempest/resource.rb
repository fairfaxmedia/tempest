module Tempest
  class Resource
    include Tempest

    class Ref
      include Tempest::BaseRef

      RefClass = Tempest::Resource
      RefType  = 'resource'
      RefKey   = 'resources'

      def att(*key)
        key = key.map {|k| Util.key(k) }.join('.')
        Function.new('Fn::GetAtt', @name, key)
      end
    end

    attr_accessor :name, :type, :tmpl

    def initialize(tmpl, name, type, properties)
      @name       = name
      @tmpl       = tmpl
      @type       = type
      @properties = properties
      @depends_on = []
    end

    def compile
      hash = { 'Type' => @type }
      unless @depends_on.empty?
        hash['DependsOn'] = Tempest::Util.compile(@depends_on.uniq)
      end
      unless @properties.empty?
        hash['Properties'] = Tempest::Util.compile(@properties)
      end
      hash
    end

    def to_h
      hash = { 'Type' => @type }
      hash['DependsOn' ] = @depends_on.uniq unless @depends_on.empty?
      hash['Properties'] = @properties      unless @properties.empty?
      hash
    end
    alias :tempest_h :to_h
  end
end
