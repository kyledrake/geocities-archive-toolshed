require 'fileutils'

# This particular filename is causing file traverse issues, fix.
# It wasn't working for the web site anyways, so fix that too.

if ARGV.length != 1
  puts "usage: file.rb archive_path"
  exit
end

fix_path = File.join ARGV[0], 'TimesSquare', 'Corridor', '1041'
FileUtils.mv File.join(fix_path, "exerc\xEDcio.gif"), File.join(fix_path, 'exercicio.gif')
`sed -i 's/exerc\xEDcio.gif/exercicio.gif/g' #{File.join fix_path, 'index.html'}`
