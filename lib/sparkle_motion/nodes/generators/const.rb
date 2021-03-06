module SparkleMotion
  module Nodes
    module Generators
      # For debugging, output 1.0 all the time.
      class Const < Generator
        def initialize(lights:, value: 1.0)
          super(lights: lights)
          @lights.times do |n|
            self[n] = value
          end
        end
      end
    end
  end
end
