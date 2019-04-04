if ARGV.length != 2
  puts "usage: capture.rb base_path source_dir dest_dir"
end

require 'rubygems'
require 'bundler/setup'
require 'etc'
require 'find'
require 'concurrent-ruby'
require 'pry-byebug'
require 'phantomjs'
require 'mini_magick'

CORES = Etc.nprocessors
BASE_PATH = ARGV[0] # /var/www/html
SOURCE_DIR = ARGV[1] # www.geocities.com
DEST_DIR = ARGV[2] # /var/www/html/screenshots
THREAD_COUNT = 30

pool = Concurrent::ThreadPoolExecutor.new(
   min_threads: THREAD_COUNT,
   max_threads: THREAD_COUNT,
   max_queue: THREAD_COUNT,
   fallback_policy: :caller_runs
)

def screenshot(url, output_path)
  Phantomjs.run('./screenshot.js', url, output_path)
end

Find.find(ARGV[0]) do |path|
  next unless path =~ /\.html?$/
  next if FileTest.directory?(path)

  url = path.gsub(BASE_PATH+'/', '')

  output_path = File.join(DEST_DIR, url+'.png')

  if File.exist?(output_path)
    puts "skipping #{url}"
    next
  end

  sleep 0.1 until pool.remaining_capacity > 0

  puts url

  pool.post do
    Phantomjs.run './screenshot.js', 'http://'+url, output_path

    # PhantomJS only makes transparent PNGs, we add a white background layer here.
    image = MiniMagick::Image.open output_path
    image.alpha 'remove'
    image.alpha 'off'
    image.format 'png'
    image.write output_path
  end
end

pool.shutdown
pool.wait_for_termination
