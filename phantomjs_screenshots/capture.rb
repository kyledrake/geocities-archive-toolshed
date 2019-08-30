if ARGV.length != 2
  puts "usage: capture.rb base_path dest_dir"
  exit
end

require 'rubygems'
require 'bundler/setup'
require 'etc'
require 'find'
require 'concurrent-ruby'
require 'pry-byebug'
require 'phantomjs'
require 'mini_magick'
require 'open3'
require 'timeout'

CORES = Etc.nprocessors
BASE_PATH = ARGV[0] # /var/www/html/www.geocities.com
DEST_DIR = ARGV[1] # /var/www/html/screenshots
THREAD_COUNT = CORES
HARD_TIMEOUT = 15

# Prime the PhantomJS install
Phantomjs.path

if File.exist?('./bad-urls.txt')
  $bad_urls_read = File.readlines('./bad-urls.txt')
else
  $bad_urls_read = []
end

# For some reason these sites behave badly, so we're moving them out of the attempts list
$bad_urls = File.open('./bad-urls.txt', 'a')

def write_bad_url(url)
  $bad_urls.write(url+"\n")
end

$mutex = Mutex.new

def out(text)
  $mutex.synchronize { print text }
end

pool = Concurrent::ThreadPoolExecutor.new(
  min_threads: THREAD_COUNT,
  max_threads: THREAD_COUNT,
  max_queue: THREAD_COUNT,
  fallback_policy: :caller_runs
)

Find.find(ARGV[0]) do |path|
  begin
    next unless path =~ /\.html?$/
  rescue ArgumentError
    print "SKIPPING UTF8 ERROR"
    next
  end
  next if FileTest.directory?(path)

  url = path.gsub(BASE_PATH+'/', '')

  if $bad_urls_read.include?(url+"\n")
    out "#{url}: BAD\n"
    next
  end
  output_path = File.join DEST_DIR, url
  output_path_png = output_path+'.png'
  output_path_jpg = output_path+'.jpg'

#  if File.exist?(output_path)
#    out "#{url}: EXISTS\n"
#    next
#  end
  sleep 0.1 until pool.remaining_capacity > 0

  pool.post do
    `timeout -k 5 #{HARD_TIMEOUT} #{Phantomjs.path} ./screenshot.js http://#{url} #{output_path_png}`
    if !File.exist?(output_path_png)
      out "#{url}: NO IMAGE\n"
      write_bad_url url
    else
      image = MiniMagick::Image.open output_path_png

      # PhantomJS only makes transparent PNGs, we add a white background layer here if we're using PNG.
      #image.alpha 'remove'
      #image.alpha 'off'
      #image.format 'png'
      #image.write output_path

      image.resize '640x480'
      image.format 'jpg'
      image.quality '90'
      image.write output_path_jpg
      FileUtils.rm output_path_png


      out "#{url}: DONE\n"
    end
  end
end

pool.shutdown
pool.wait_for_termination
