# frozen_string_literal: true
require 'yaml'
require 'find'
require 'addressable'
require 'pry'

if ARGV.length != 4
  puts "usage: 002-find-missing-files.rb archive_path missing-files.txt missing-checkpoint.txt missing-dupes.txt"
  exit
end

NEIGHBORHOODS    = YAML.load_file File.join('lib', 'neighborhoods.yaml')
LC_NHOODS        = NEIGHBORHOODS.keys.collect {|n| n.downcase}
ARCHIVE_PATH     = ARGV[0]
CHECKPOINT_PATH  = ARGV[1]
DUPES_PATH       = ARGV[1]
CANONICAL_SCHEME = 'http'
CANONICAL_HOST   = 'www.geocities.com'
VALID_HOSTS      = [nil, 'geocities.com', 'www.geocities.com']
VALID_SCHEMES    = [nil, 'http', 'https']

# Attempt to get case correct.
def case_sensitive_path(archive_path, path='')
  path ||= ''
  clean = [archive_path]
  parts = path.to_s.split '/'

  parts.each do |part|
    next if part.empty? || part == '.' || part == '..'
    begin
      files = Dir.entries(File.join(clean)).select {|f| f =~ /^#{part}$/i}
    rescue Errno::ENOENT
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

  # Scrub dangerous carriage garbage (everything below 32 bytes.. http://www.asciitable.com/)
  clean_path.each_codepoint do |c|
    #raise ArgumentError, 'invalid character for filename' if c < 32
    return nil if c < 32
  end

  clean_path
end

NEIGHBORHOODS.keys.sort.each do |neighborhood|
  Find.find(File.join ARCHIVE_PATH, neighborhood) do |path|
    next if File.directory? path
    file = IO.binread path
    links = (file.scan(/src\s*=\s*"(.+?)"/) + file.scan(/href\s*=\s*"(.+?)"/)).flatten

    links.each do |link|
      begin
        uri = Addressable::URI.parse link.strip
      rescue
        # not dealing with crazy links
        next
      end

      next unless VALID_HOSTS.include? uri.host
      next unless VALID_SCHEMES.include? uri.scheme

      # Only focusing on old neighborhood files for now, not the root username sites.
      match = uri.path.match(/^\/?(\w+)/)
      next if match && !LC_NHOODS.include?(match.captures.first.downcase)

      if uri.host.nil? # relative url like: <img src="earth.gif">
        uri.scheme = CANONICAL_SCHEME unless uri.scheme == CANONICAL_SCHEME
        uri.host   = CANONICAL_HOST   unless uri.host   == CANONICAL_HOST

        if uri.path[0] == '/'
          # TODO
          # I guess there could be some people using "/Tokyo/2343/example.gif" as uris...
          file_path  = ARCHIVE_PATH + uri.path
        else
          file_path = File.join File.dirname(path), uri.path
          uri.path  = File.dirname(path).gsub(ARCHIVE_PATH, '') + '/' + uri.path
        end
      else
        file_path = ARCHIVE_PATH + uri.path
      end

      uri.path = Pathname.new(uri.path).cleanpath.to_s
      file_path = Pathname.new(file_path).cleanpath.to_s
      next unless file_path =~ /^#{ARCHIVE_PATH}/

      puts "#{file_path},#{uri}"
    end
  end
end
