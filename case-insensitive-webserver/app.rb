# Webserver that serves local files case insensitively for serving geocities pages.
# Uses Host to find the right directory to look in.
# Expecting the archive directory created by the despens/Geocities scripts.
# gem install bundler
# bundle install
# ARCHIVE_PATH=path/to/archive bundle exec ruby app.rb

require 'sinatra'
#require 'pry-byebug'

raise ArgumentError, 'provide an ARCHIVE_PATH environment variable.' if ENV['ARCHIVE_PATH'].nil?
raise ArgumentError, 'ARCHIVE_PATH does not exist' unless File.directory?(ENV['ARCHIVE_PATH'])

before do
  path = scrubbed_path ENV['ARCHIVE_PATH'], File.join(request.host, request.path)
  not_found if path.nil?
  send_file path
end

def scrubbed_path(archive_path, path='')
  path ||= ''
  clean = [archive_path]

  parts = path.to_s.split '/'

  parts.each do |part|
    next if part.empty? || part == '.' || part == '..'
    files = Dir.entries(File.join(clean)).select {|f| f =~ /^#{part}$/i}
    return nil if files.empty?
    clean << files.first
  end

  clean_path = File.join clean

  # Scrub carriage garbage (everything below 32 bytes.. http://www.asciitable.com/)
  clean_path.each_codepoint do |c|
    #raise ArgumentError, 'invalid character for filename' if c < 32
    return nil if c < 32
  end

  # Hunt for indexes if dir
  if File.directory? clean_path
    ['index.html', 'index.htm'].each do |fn|
      candidate = File.join clean_path, fn
      return candidate if File.file? candidate
    end

    return nil
  end

  clean_path
end
