# frozen_string_literal: true
# https://github.com/internetarchive/wayback/blob/master/wayback-cdx-server/README.md
# apt-get install wget
# combine the files indo a single cdx and then run 001-build-filelist.rb
require 'http'
require 'pry'
require 'addressable'
require 'fileutils'

if ARGV.length != 1
  puts "usage: ruby mega-maid.rb out_file.cdx"
  exit
end

CDX_NUM_PAGES = 'http://web.archive.org/cdx/search/cdx?url=geocities.com&matchType=host&showNumPages=true&filter=statuscode:200'
CDX_SEARCH_BASE = "http://web.archive.org/cdx/search/cdx?url=geocities.com&matchType=host&filter=statuscode:200&page="
TMP_DIR = '/tmp'
OUT_FILE = ARGV[0]
TMP_DL_FILE_PATH = File.join TMP_DIR, 'out_file.cdx'
TMP_RM_QS_FILE_PATH = File.join TMP_DIR, 'out_file_rm_qs.cdx'
TMP_SORTED_FILE_PATH = File.join TMP_DIR, 'out_file_sorted.cdx'

NUM_PAGES = HTTP.get(CDX_NUM_PAGES).to_s.to_i

cdx_pagelist = ''

out_file = File.open TMP_DL_FILE_PATH, 'wb'

(0..NUM_PAGES).each do |page|
  puts "downloading page #{page}..."
  body = HTTP.get("#{CDX_SEARCH_BASE}#{page.to_s}").body

  while data = body.readpartial
    out_file.write data
  end
end

out_file.close

puts "ripping out query strings"

file = File.open TMP_RM_QS_FILE_PATH, 'wb'

File.open(TMP_DL_FILE_PATH, 'rb').each do |line_string|
  line_string.downcase!
  line = line_string.split ' '
  line[0] = line[0].sub(/\?[^\s\/]+/, '')
  line[2] = line[2].sub(/\?[^\s\/]+\/?/, '')
  file.write line.join(' ')+"\n"
end

file.close
FileUtils.rm TMP_DL_FILE_PATH

puts "sorting by timestamp and key"
`cat #{TMP_RM_QS_FILE_PATH} | sort -k1,1 -k2,2n >#{TMP_SORTED_FILE_PATH}`

FileUtils.rm TMP_RM_QS_FILE_PATH
FileUtils.mv TMP_SORTED_FILE_PATH, OUT_FILE
puts "done, saved to #{OUT_FILE}"
