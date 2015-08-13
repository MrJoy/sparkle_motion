module Node
  module Simulation
    # Manage and run a simulation of just `sin(x + y)`.
    class Wave2 < Base
      def initialize(lights:, initial_state: nil, speed:)
        super(lights: lights, initial_state: initial_state)
        @speed = speed
      end

      def update(t)
        @lights.times do |n|
          self[n] = (Math.sin((n * @speed.x) + (t * @speed.y)) * 0.5) + 0.5
        end
        super(t)
      end
    end
  end
end