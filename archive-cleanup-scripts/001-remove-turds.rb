# This script removes the Geocities embedded server turds.
# They're useless now, everybody hated them then, and I
# feel a special kind of gratification getting rid of them.

require 'find'
require 'fileutils'

if ARGV.length != 1
  puts "usage: 001-remove-turds.rb archive_path"
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

  begin
    fp = File.open path, 'rb'
    contents = fp.read
    fp.close

    contents = contents.sub /<!-- following code added by server. PLEASE REMOVE -->.*<!-- preceding code added by server. PLEASE REMOVE -->\r?\n/m, ''
    contents = contents.sub /<!-- text below generated by server. PLEASE REMOVE -->.*/m, ''

    fp = File.open path, 'wb'
    fp.write contents
    fp.close
  ensure
    FileUtils.touch path, mtime: mtime
  end

  puts "#{path}: OK"
end
