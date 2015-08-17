module Tempest
  module Util
    class Key
      def initialize(key)
        if key.is_a? String
          @key = key
        elsif key.is_a? Symbol
          @key = key.to_s.gsub(%r((^|_)\w)) {|ch| ch.delete('_').upcase }
        elsif key.is_a? Key
          @key = key.to_s
        else
          raise "Invalid key type: #{key.class}"
        end
      end

      def inspect
        "#<Key:#{@key}>"
      end

      def to_s
        @key
      end

      def +(other)
        other = Key.new(other) unless other.is_a?(Key)

        Key.new(self.to_s + other.to_s)
      end

      def eql?(other)
        other = Key.new(other) unless other.is_a?(Key)

        self.to_s == other.to_s
      end

      def hash
        @key.hash
      end
    end

    def self.key(name)
      return name if name.is_a?(Key)
      Key.new(name)
    end
  end
end
