module SparkleMotion
  module LaunchPad
    module Widgets
      # Class to represent a slider-style control on a Novation Launchpad.
      class HorizontalSlider < Widget
        attr_accessor :on_change

        def initialize(launchpad:, position:, size:, colors:, on_change: nil, value: 0)
          super(launchpad: launchpad,
                position:  position,
                size:      SparkleMotion::Vector2.new(size, 1),
                colors:    colors,
                value:     value)
          @on_change = on_change
        end

        def render
          (0..max_v).each do |xx|
            change_grid(x: xx, y: 0, color: (value && value >= xx) ? colors.on : colors.off)
          end
          super
        end

        def update(*args)
          super(*args)
          on_change.call(value) if on_change
        end

      protected

        def on_down(x:, y:)
          @value = x
          super(x: x, y: y)
          on_change.call(value) if on_change
        end
      end
    end
  end
end
