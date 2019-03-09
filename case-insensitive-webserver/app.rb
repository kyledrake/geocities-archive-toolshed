# Webserver that serves local files case insensitively for serving geocities pages.
# Uses Host to find the right directory to look in.
# Expecting the archive directory created by the despens/Geocities scripts.
# gem install sinatra
# ARCHIVE_PATH=path/to/archive ruby app.rb

require 'sinatra'

raise ArgumentError, 'provide an ARCHIVE_PATH environment variable.' if ENV['ARCHIVE_PATH'].nil?
raise ArgumentError, 'ARCHIVE_PATH does not exist' unless File.directory?(ENV['ARCHIVE_PATH'])

get %r{.*} do
  path = File.join ENV['ARCHIVE_PATH'], scrubbed_path(request.host), scrubbed_path(request.path)

  # 1 - if it's a file we can see, just send it over
  send_file path if File.file?(path)

  # 2 - if it's a directory, look for an index html. If not found, pass file list.
  if File.directory?(path)
    index_files = Dir.entries(path).select {|f| f =~ /index\.html?/i}
    send_file(File.join(path, index_files.first)) unless index_files.empty?

    return %{<a href="..">..</a><br>} + Dir.entries(path).reject {|f| File.directory?(f)}.collect {|f| %{<a href="#{f}">#{f}</a><br>}}.join
  end

  basename = File.basename path
  dirname  = File.dirname path

  files = Dir.entries(dirname).reject { |f| File.directory?(f) }.select {|f| f =~ /#{basename}/i}
  not_found if files.empty?
  file_path = File.join dirname, files.first
  send_file file_path
end

def scrubbed_path(path='')
  path ||= ''
  clean = []

  parts = path.to_s.split '/'

  parts.each do |part|
    next if part.empty? || part == '.'
    clean << part if part != '..'
  end

  clean_path = clean.join '/'

  # Scrub carriage garbage (everything below 32 bytes.. http://www.asciitable.com/)
  clean_path.each_codepoint do |c|
    raise ArgumentError, 'invalid character for filename' if c < 32
  end

  clean_path
end
