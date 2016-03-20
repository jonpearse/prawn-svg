class Prawn::SVG::Document
  begin
    require 'css_parser'
    CSS_PARSER_LOADED = true
  rescue LoadError
    CSS_PARSER_LOADED = false
  end

  DEFAULT_FALLBACK_FONT_NAME = "Times-Roman"

  # An +Array+ of warnings that occurred while parsing the SVG data.
  attr_reader :warnings

  attr_reader :root,
    :sizing,
    :fallback_font_name,
    :url_loader,
    :css_parser, :elements_by_id, :gradients

  def initialize(data, bounds, options)
    @css_parser = CssParser::Parser.new if CSS_PARSER_LOADED

    @root = REXML::Document.new(data).root
    @warnings = []
    @options = options
    @elements_by_id = {}
    @gradients = {}
    @fallback_font_name = options.fetch(:fallback_font_name, DEFAULT_FALLBACK_FONT_NAME)

    @url_loader = Prawn::SVG::UrlLoader.new(
      enable_cache:          options[:cache_images],
      enable_web:            options.fetch(:enable_web_requests, true),
      enable_file_with_root: options[:enable_file_requests_with_root]
    )

    @sizing = Prawn::SVG::Calculators::DocumentSizing.new(bounds, @root.attributes)
    sizing.requested_width = options[:width]
    sizing.requested_height = options[:height]
    sizing.calculate

    @axis_to_size = {:x => sizing.viewport_width, :y => sizing.viewport_height}

    yield self if block_given?
  end

  def x(value)
    points(value, :x)
  end

  def y(value)
    sizing.output_height - points(value, :y)
  end

  def distance(value, axis = nil)
    value && points(value, axis)
  end

  def points(value, axis = nil)
    Prawn::SVG::Calculators::Pixels.to_pixels(value, @axis_to_size.fetch(axis, sizing.viewport_diagonal))
  end
end
