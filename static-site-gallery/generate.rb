# frozen_string_literal: true
require 'erb'
require 'find'
require 'nokogiri'
require 'pry'

unless ARGV.length == 1
  puts "usage: ruby generate.rb archive_path"
end

ARCHIVE_PATH = ARGV[0]
ASSET_PATH = File.join ARCHIVE_PATH, '_assets'
NEIGHBORHOODS = YAML.load_file File.join('..', 'archive-cleanup-scripts', 'lib', 'neighborhoods.yaml')

FileUtils.mkdir_p ASSET_PATH
FileUtils.cp_r '_assets', File.join(ASSET_PATH, '/')

template = ERB.new File.read(File.join('templates', 'gallery.erb'))

NEIGHBORHOODS.keys.each do |neighborhood|
  sites = []

  addresses = Dir.glob(ARCHIVE_PATH+'/'+neighborhood+'/*')
              .collect {|a| a.gsub("#{ARCHIVE_PATH}/#{neighborhood}/", '')}
              .select  {|a| !NEIGHBORHOODS[neighborhood].include?(a)}
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

    html_doc = Nokogiri::HTML index_data
    titles = html_doc.css('title')

    title = titles.empty? ? "#{neighborhood}/#{address}" : titles[0].text

    sites << {
      relative_url: '/'+neighborhood+'/'+address,
      title: title,
      index_filename: index_filename,
      last_updated: mtime
    }

    #puts index_path
  end
  File.write File.join(ARCHIVE_PATH, neighborhood, 'index.html'), template.result(binding)
end
