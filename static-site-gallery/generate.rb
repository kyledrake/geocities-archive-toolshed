# frozen_string_literal: true
require 'erb'
require 'find'
require 'nokogiri'
require 'yaml'
require 'pry'

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
    index_data = IO.binread index_path

    # skip pages that never were started
    next if index_data.match(/I haven't started building my site yet/)
    next if index_data.match(/have not moved in yet/) && index_data.match(/The description of my page is/)
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
      last_updated: mtime
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

