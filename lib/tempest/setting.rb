module Tempest
  class Setting
    attr_accessor :key, :value

    # In the simplest usage, value will be the value of the Setting.
    # A block may be provided to extend/modify the value of a parent setting,
    # in which case the value setting becomes a default.
    # e.g. if this expects a parent setting to be an array, you might have:
    #   set(:key => []) do |prev|
    #     prev += [:some_extra_value]
    #   end
    # So if parent setting is not found, `prev` will be set to the default of `[]`.
    def initialize(key, value = nil, &block)
      @key = key
      @value = value

      if block_given?
        @block = block
      else
        @block = nil
      end
    end

    # Default values might be supplied to #initialize, we allow for these to be
    # overwritten once.
    def is_set?
      @is_set
    end

    def set(value, &block)
      @value = value
      @block = block
      @is_set = true
      self
    end

    def value
      v = @value
      v = v.value while v.is_a? Setting

      if @block.nil?
        v
      else
        @block.call(v)
      end
    end
  end
end
