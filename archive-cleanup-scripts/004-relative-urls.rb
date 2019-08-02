# converts any geocities.com urls to relative urls.

require 'find'
require 'fileutils'
require 'pry'

if ARGV.length != 1
  puts "usage: 004-relative-urls.rb archive_path"
  exit
end

Find.find(ARGV[0]) do |path|
  begin
    next unless path =~ /\.html?$/
  rescue
    puts "likely UTF8 filename error, skipping"
    next
  end
  next if FileTest.directory?(path)
  mtime = File.mtime path
  changed = false

  begin
    file = IO.binread path
    links = (file.scan(/href\s*=\s*["']([^"']+)/i) + file.scan(/src\s*=\s*["']([^"']+)/i)).flatten.compact
    change_count = 0
    links.each do |link|
      if link.match /http:\/\/(www\.)?geocities.com/i
        changed = true
        change_count += 1
        relative_link = link.sub /http:\/\/(www\.)?geocities.com/i, ''
        file.sub! link, relative_link
      end
    end
    next unless changed
    fp = File.open path, 'wb'
    fp.write file
    fp.close

    puts "#{path}\t#{change_count}"
  ensure
    FileUtils.touch path, mtime: mtime
  end
end
