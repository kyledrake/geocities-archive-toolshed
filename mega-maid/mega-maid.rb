# frozen_string_literal: true
# https://github.com/internetarchive/wayback/blob/master/wayback-cdx-server/README.md
# apt-get install wget
require 'http'
require 'pry'
require 'addressable'
require 'fileutils'

if ARGV.length != 1
  puts "usage: ruby mega-maid.rb out_dir"
  exit
end

OUT_DIR = ARGV[0]

FileUtils.mkdir_p OUT_DIR

NUM_PAGES = HTTP.get('http://web.archive.org/cdx/search/cdx?url=geocities.com&matchType=host&showNumPages=true&filter=statuscode:200').to_s.to_i

(0..NUM_PAGES).each do |page|
  filename = "#{page.to_s}.cdx"
  filepath = File.join OUT_DIR, filename
  `wget --quiet -O #{File.join OUT_DIR, page.to_s}.cdx "http://web.archive.org/cdx/search/cdx?url=geocities.com&matchType=host&filter=statuscode:200&page=#{page.to_s}"`
  puts "#{filename}: #{File.size filepath}"
end
