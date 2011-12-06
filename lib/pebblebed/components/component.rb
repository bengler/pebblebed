class Pebblebed::Component::Builder
  def initialize(component)
    @component = component || Pebblebed::Component.new
  end

  def title(title)
    @component.title = title
  end

  def 
end


class Pebblebed::Component
  attr_reader :title, :description, :params




end