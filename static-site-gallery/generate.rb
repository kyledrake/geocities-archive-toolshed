# frozen_string_literal: true
require 'erb'
require 'find'
require 'nokogiri'
require 'yaml'
require 'pry'
require 'rmagick'

unless ARGV.length == 1
  puts "usage: ruby generate.rb archive_path"
  exit
end

ARCHIVE_PATH = ARGV[0]
ASSET_PATH = File.join ARCHIVE_PATH, '_assets'
NEIGHBORHOODS = YAML.load_file File.join('..', 'archive-cleanup-scripts', 'lib', 'neighborhoods.yaml')

FileUtils.mkdir_p ASSET_PATH
FileUtils.cp_r '_assets', File.join(ASSET_PATH, '/')

TEMPLATE = ERB.new File.read(File.join('templates', 'gallery.erb'))


# Derived from the boring website detector: https://gist.github.com/kyledrake/bf07ffe794698774b956
def screenshot_bad?(path)
  begin
    img =  Magick::Image.read(path).first
  rescue Magick::ImageMagickError
    return true
  end

  pix = img.scale(1, 1)
  average_color = pix.pixel_color(0,0)

  #color_hex = average_color.to_color(Magick::AllCompliance, false, (defined?(Magick::QuantumDepth) ? Magick::QuantumDepth : 16), true)

  #color_hex.sub! '#', ''
  #color_integer = color_hex.to_i 16

  score = (65535*3) - average_color.red - average_color.green - average_color.blue

  img.destroy!
  #GC.start

  #puts "---\n#{path}:\n#{average_color}\n#{color_hex}\n#{color_integer}\nSCORE: #{score}\n\n"

  if score < 500
    return true
  end

  false
end

def generate_template(neighborhood)
  neighborhood_path = File.join ARCHIVE_PATH, neighborhood
  return nil unless Dir.exist? neighborhood_path
  sites = []

  addresses = Dir.glob(File.join(neighborhood_path, '/*'))
              .collect {|a| a.gsub(File.join(neighborhood_path, '/'), '')}
              .select  {|a| a.to_i != 0}
              .sort

  addresses.each do |address|
    site_path = File.join ARCHIVE_PATH, neighborhood, address

    # May want to add more here - CaSeD InDex.html. Also found some index1.html and index2.html entries.
    index_filename = nil
    index_filename = 'index.html' if File.exist?(File.join(site_path, 'index.html'))
    index_filename = 'index.htm' if index_filename.nil? && File.exist?(File.join(site_path, 'index.htm'))
    next if index_filename.nil?

    index_path = File.join site_path, index_filename
    next if FileTest.directory? index_path

    relative_url = '/'+neighborhood+'/'+address

    screenshot_path = "/_assets/screenshots#{relative_url}/#{index_filename}.png"

    next unless File.exist? File.join(ARCHIVE_PATH, screenshot_path)
    next if screenshot_bad?(File.join(ARCHIVE_PATH, screenshot_path))

    index_data = IO.binread index_path

    # skip pages that never were started
    next if index_data.match(/I haven't started building my site yet/)
    next if index_data.match(/have not moved in yet/)
    next if index_data.match(/has not moved in yet/)

    has_audio = false
    has_audio = true if index_data.match(/src\s*=\s*["'](.+\.(wav|midi?))["']/i)

    mtime = File.mtime index_path

    # TODO investigate syntax errors and find better fix
    begin
      html_doc = Nokogiri::HTML index_data
    rescue Nokogiri::XML::SyntaxError
      next
    end

    titles = html_doc.css('title')

    title = titles.empty? ? "#{neighborhood}/#{address}" : titles[0].text
    title = '(untitled)' if title.empty?

    sites << {
      relative_url: '/'+neighborhood+'/'+address,
      title: title,
      index_filename: index_filename,
      last_updated: mtime,
      has_audio: has_audio,
      screenshot_path: screenshot_path
    }

    #puts index_path
  end
  index_write_path = File.join(ARCHIVE_PATH, neighborhood, 'index.html')
  puts "writing to #{index_write_path}"
  File.write index_write_path, TEMPLATE.result(binding)
end

NEIGHBORHOODS.keys.each do |neighborhood|
  generate_template neighborhood
  NEIGHBORHOODS[neighborhood].each {|sn| generate_template "#{neighborhood}/#{sn}"}
end
