# A class to help consumers of layout parts embed parts

class Pebblebed::Parts

  attr_reader :composition_strategy

  # A composition strategy is a way to get from an url and a params hash to markup that will
  # render the part into the page. Pluggable strategies to support different production 
  # environments. SSI is provided by Nginx, ESI by Varnish and :direct is a fallback
  # for the development environment.

  @composition_strategies = {}

  def initialize(connector)
    @composition_strategy = :ssi # <- It's the best! Use Nginx with SSI
    @preloadable = {} # <- A cache to remember which parts are preloadable
    @connector = connector
  end

  # All part manifests for all configured pebbles as a hash of DeepStructs
  def manifests
    @manifests ||= @connector.quorum.get("/parts")
    @manifests.each { |k,v| @manifests.delete(k) if v.is_a?(Pebblebed::HttpError) }
    @manifests
  end

  def reload_manifest
    @manifests = nil
  end

  # The strategy for composing multiple parts into a page. Default: `:ssi`
  def composition_strategy=(value)
    raise ArgumentError, "Unknown composition strategy '#{value}'" unless composition_strategies.keys.include?(value)
    @composition_strategy = value
  end

  # Generates the markup for the part according to the composition strategy
  def markup(partspec, params = nil)
    ["<div data-pebbles-component=\"#{partspec}\" #{self.class.data_attributes(params || {})}>",
     composition_markup_from_partspec(partspec, params),
     "</div>"].join
  end

  def stylesheet_urls
    manifests.keys.map do |service|
      @connector[service].service_url("/parts/assets/parts.css")
    end
  end

  def javascript_urls
    manifests.keys.map do |service|
      @connector[service].service_url("/parts/assets/parts.js")
    end
  end

  # Register a new composition strategy handler. The block must accept two parameters:
  # |url, params| and is expected to return whatever markup is needed to make it happen.
  def self.register_composition_strategy(name, &block)
    @composition_strategies[name.to_sym] = block
  end

  private

  # Check the manifests to see if the part has a server side action implemented.
  def preloadable?(partspec)
    @preloadable[partspec] ||= raw_part_is_preloadable?(partspec)
  end

  def raw_part_is_preloadable?(partspec)
    service, part = self.class.parse_partspec(partspec)
    $stderr.puts manifests.inspect
    return false unless service = manifests[service.to_sym]
    return false unless part_record = service[part]
    return false if part_record.is_a?(::Pebblebed::HttpError)
    return part_record.part.preloadable
  end  

  def composition_markup_from_partspec(partspec, params)
    return '' unless preloadable?(partspec)
    service, part = self.class.parse_partspec(partspec)
    composition_markup(
      @connector[service].service_url("/parts/#{part}"), params)
  end

  def self.composition_strategies
    @composition_strategies
  end

  def composition_markup(url, params)
    self.class.composition_strategies[@composition_strategy].call(url, params)
  end

  def self.parse_partspec(partspec)
    /^(?<service>[^\.]+)\.(?<part>.*)$/ =~ partspec
    [service, part]
  end

  # Create a string of data-attributes from a hash
  def self.data_attributes(hash)
    hash.map { |k,v| "data-#{k.to_s.gsub('_', '-')}=\"#{v}\"" }.join(' ')
  end
end

# -------------------------------------------------------------------------------

# SSI (Nginx): http://wiki.nginx.org/HttpSsiModule
Pebblebed::Parts.register_composition_strategy :ssi do |url, params|
  "<!--# include virtual=\"#{URI.parse(url.to_s).path}?#{QueryParams.encode(params || {})}\" -->"
end

# ESI (Varnish): https://www.varnish-cache.org/trac/wiki/ESIfeatures
Pebblebed::Parts.register_composition_strategy :esi do |url, params|
  "<esi:include src=\"#{URI.parse(url.to_s).path}?#{QueryParams.encode(params || {})}\"\/>"
end

# Just fetches the content and returns it. ONLY FOR DEVELOPMENT
Pebblebed::Parts.register_composition_strategy :direct do |url, params|
  begin
    Pebblebed::Connector.new.get(url, params)
  rescue HttpError => e
    "<span class='pebbles_error'>'#{url}' with parameters #{params.to_json} failed (#{e.status}): #{e.message}</span>"
  end
end
