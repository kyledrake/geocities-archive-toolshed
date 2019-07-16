# frozen_string_literal: true
require 'yaml'
require 'find'
require 'addressable'
require 'digest'
require 'pathname'

if ARGV.length != 4
  puts "usage: 002-find-missing-files.rb archive_path subdir_path missing-files.txt checkpoint.txt"
  exit
end

NEIGHBORHOODS      = YAML.load_file File.join('lib', 'neighborhoods.yaml')
LC_NHOODS          = NEIGHBORHOODS.keys.collect {|n| n.downcase}
ARCHIVE_PATH       = ARGV[0]
SUBDIR_PATH        = ARGV[1]
MISSING_FILES_PATH = ARGV[2]
CHECKPOINT_PATH    = ARGV[3]
CANONICAL_SCHEME   = 'http'
CANONICAL_HOST     = 'www.geocities.com'
VALID_HOSTS        = [nil, 'geocities.com', 'www.geocities.com']
VALID_SCHEMES      = [nil, 'http', 'https']

$missing_files = File.open MISSING_FILES_PATH, 'ab'

# Attempt to get case correct.
def case_sensitive_path(archive_path, path='')
  path ||= ''
  clean = [archive_path]
  parts = path.to_s.split '/'

  parts.each do |part|
    next if part.empty? || part == '.' || part == '..'
    begin
      files = Dir.entries(File.join(clean)).select {|f| f =~ /^#{part}$/i}
    rescue RegexpError
      return nil
    rescue Errno::ENOENT
      clean << part
      next
    rescue ArgumentError
      return nil
    rescue Encoding::CompatibilityError
      return nil
    rescue Errno::ENOTDIR
      clean << part
      next
    end

    if files.empty?
      clean << part
    else
      clean << files.first
    end
  end

  clean_path = File.join clean

  # Scrub carriage garbage (everything below 32 bytes.. http://www.asciitable.com/)
  clean_path.each_codepoint do |c|
    #raise ArgumentError, 'invalid character for filename' if c < 32
    return nil if c < 32
  end

  clean_path
end

cp_cnt = 0
cp     = File.exist?(CHECKPOINT_PATH) ? File.read(CHECKPOINT_PATH) : nil
cp_hit = cp.nil?

Find.find(File.join(ARCHIVE_PATH, SUBDIR_PATH)) do |path|
  if !cp_hit
    if cp == path
      puts "resuming at #{path}"
      cp_hit = true
    else
      next
    end
  end

  File.write(CHECKPOINT_PATH, path) if cp_cnt%1000==0
  cp_cnt += 1

  begin
    next unless path =~ /\.html?$/
  rescue
    puts "likely UTF8 filename error, skipping"
    next
  end

  next if File.directory? path
  file = IO.binread path

  # suck out href and src values.. this may not be complete!
  links = (file.scan(/src\s*=\s*["'](.+)["']/i) + file.scan(/href\s*=\s*["'](.+)["']/i)).flatten.compact

  links.each do |link|
    # rip out anchors and query strings
    link.gsub! /#.+$|\?.+$/, ''

    # decode urlencoded space at eol?
    link.gsub! /\/%20$/, ' '

    next if link.empty?
    begin
      uri = Addressable::URI.parse link.strip
    rescue
      # not dealing with crazy links
      next
    end

    # skip crazy/irrelevant uris
    next unless VALID_HOSTS.include? uri.host
    next unless VALID_SCHEMES.include? uri.scheme
    next if     uri.path.empty?
    next if     uri.path == '/'

    # lots of weird garbage and html in these paths
    next if     uri.path =~ /[\n=<>@]/

    # and mailto links
    next if     uri.path =~ /mailto/

    # relative url like: <img src="earth.gif">
    if uri.host.nil?
      if uri.path[0] == '/'
        file_path  = ARCHIVE_PATH + uri.path
      else
        file_path = File.join File.dirname(path), uri.path
        uri.path  = File.dirname(path).gsub(ARCHIVE_PATH, '') + '/' + uri.path
      end
    else # absolute path like http://www.geocities.com/Tokyo/2033/example.jpg
      file_path = ARCHIVE_PATH + uri.path
    end

    # scrub out relative paths
    uri.path  = Pathname.new(uri.path).cleanpath.to_s
    file_path = Pathname.new(file_path).cleanpath.to_s

    # skip path if it's below the archive root
    next unless file_path =~ /^#{ARCHIVE_PATH}/

    # best attempt at case sensitive file path
    file_path = case_sensitive_path ARCHIVE_PATH, uri.path
    next if file_path.nil?

    # set canonical scheme, host
    begin
      uri.scheme = CANONICAL_SCHEME unless uri.scheme == CANONICAL_SCHEME
      uri.host   = CANONICAL_HOST   unless uri.host   == CANONICAL_HOST
    rescue => e
      puts "error: #{e.inspect}"
    end

    # skip dotfiles
    next if uri.path.match /\/\..+$/

    # add index.html if not clearly a file
    unless uri.path.match(/[^\/]+\.[^\/]+$/)
      file_path = File.join file_path, 'index.html'
    end

    # skip if we already have it.
    next if File.exist? file_path

    begin
      $missing_files.write "#{file_path}\t#{uri}\n"
    rescue Encoding::CompatibilityError
      next
    end
  end
end

$missing_files.close
