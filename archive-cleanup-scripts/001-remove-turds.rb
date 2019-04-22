=begin
  This script removes the Geocities embedded server turds. They're useless now, everybody hated them then, and I feel a special kind of gratification getting rid of them.
=end

require 'find'
require 'fileutils'
require 'pry'

if ARGV.length != 1
  puts "usage: capture.rb archive_path"
  exit
end

Find.find(ARGV[0]) do |path|
  next unless path =~ /\.html?$/
  next if FileTest.directory?(path)
  mtime = File.mtime path

  File.open(path, 'ab+') do |fp|
    contents = fp.read
    contents.gsub! /<!-- following code added by server. PLEASE REMOVE -->.*<!-- preceding code added by server. PLEASE REMOVE -->/m, ''
    contents.gsub! /<!-- text below generated by server. PLEASE REMOVE -->.*/m, ''
    fp.rewind
    fp.write contents
  end
  FileUtils.touch path, mtime: mtime
  puts "#{path}: OK"
end
