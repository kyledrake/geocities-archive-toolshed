# frozen_string_literal: true
# https://github.com/internetarchive/wayback/blob/master/wayback-cdx-server/README.md
# apt-get install wget

require 'http'
require 'pry'
require 'addressable'
require 'fileutils'

if ARGV.length != 2
  puts "usage: ruby find-missing.rb CDX_FILE_PATH ARCHIVE_DIR > missing-files.log"
  exit
end

CDX_FILE_PATH = ARGV[0]
ARCHIVE_DIR = ARGV[1]

previous_line = nil

def store(line)
  uri = Addressable::URI.parse line[2]
  file_path = File.join ARCHIVE_DIR, uri.path
  #FileUtils.mkdir_p File.dirname(file_path)

  if File.extname(uri.path) == '' && line[3] == 'text/html'
    puts "#{File.join file_path, 'index.html'}\t#{uri}"
  else
    puts "#{file_path}\t#{uri.to_s}"
  end
end

File.open(CDX_FILE_PATH, 'rb').each do |line_string|
  line = line_string.split ' '

  if previous_line.nil?
    previous_line = line
    next
  end

  if line[0] != previous_line[0]
    store previous_line
  end

  previous_line = line
end

# Last one will be the last one
store previous_line
