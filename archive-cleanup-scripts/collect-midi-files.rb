require 'find'
require 'fileutils'

ARCHIVE_PATH = ARGV[0]
MIDI_OUTPUT_DIR = ARGV[1]

midi_file_path = []

Find.find(ARCHIVE_PATH) do |path|
  if path =~ /\.midi?$/ && File.file?(path)
    midi_file_path << path
    puts path.inspect

    file_copy_path = File.join MIDI_OUTPUT_DIR, "#{File.basename path}"

    unless File.exist?(file_copy_path)
      count = 1
      until !File.exist?(file_copy_path)
        file_copy_path = File.join MIDI_OUTPUT_DIR, "#{File.basename(path, '.*')}#{count}#{File.extname path}"
        count += 1
      end
    end

    FileUtils.cp path, file_copy_path

    puts "#{path}\t#{file_copy_path}"
  end
end
