class Aspects
  @origenes

  def self.on fuente, *masFuentes
    masFuentes.unshift fuente
    @origenes = masFuentes.map { |f| f.getOrigenes() }.flatten.compact.uniq

    raise ArgumentError, 'origen vacio' unless @origenes.any?

    return @origenes
  end
end

