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

    def wrap(parent)
      @parent = parent
    end

    def value
      if @parent.nil?
        if @block.nil?
          @value
        else
          @block.call(@value)
        end
      else
        if @block.nil?
          @block.call(@parent.value)
        else
          @parent.value
        end
      end
    end
  end
end
