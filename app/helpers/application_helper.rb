module ApplicationHelper
  def svg_icon(name)
    return "<svg id=\"#{name}\" viewBox=\"0 0 24 24\"></svg>".html_safe if Rails.env.test?

    Rails.cache.fetch("icon-#{name}-#{Rails.root.join("lib/assets/icons.svg").mtime}") do
      icon_file = Rails.root.join("lib/assets/icons.svg").read
      svg = Nokogiri::HTML.parse(icon_file)
      html = svg.css("##{name}").to_html.gsub("viewbox", "viewBox")

      if !Rails.env.production? && html.blank?
        possible_icons = svg.xpath("/html/body/svg/svg").map { _1[:id] }.compact
        raise StandardError.new("Icon \"#{name}\" not found.\n\nMust be one of:\n\n#{possible_icons.join("\n")}")
      end

      html.html_safe
    end
  end

  def icon(name, classes = nil)
    classes = classes.to_s + " animate-spin" if name == "loading-spinner"
    content_tag(:svg, svg_icon(name), class: classes)
  end
end
