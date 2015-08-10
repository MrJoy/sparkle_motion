# Transform values from 0..1 into a new range.
class ContrastTransform < TransformNode
  def initialize(lights:, function:, iterations:, source:, debug: false)
    super(lights: lights, source: source, debug: debug)
    @contrast = Perlin::Curve.contrast(function, iterations)
  end

  def update(t)
    super(t) do |x|
      @contrast.call(@source[x])
    end
  end
end