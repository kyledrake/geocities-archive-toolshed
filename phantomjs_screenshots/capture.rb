if ARGV.length != 2
  puts "usage: capture.rb base_path dest_dir (also you need to install chrome in the PATH)"
  exit
end

require 'rubygems'
require 'bundler/setup'
require 'etc'
require 'find'
require 'concurrent-ruby'
require 'pry-byebug'
require 'mini_magick'
require 'open3'
require 'timeout'

CORES = Etc.nprocessors
BASE_PATH = ARGV[0] # /var/www/html/www.geocities.com
DEST_DIR = ARGV[1] # /var/www/html/screenshots
THREAD_COUNT = CORES * 3
HARD_TIMEOUT = 15

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
    path.gsub!(/%7E/i, '~')
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
    FileUtils.mkdir_p File.dirname(output_path_png)
    `timeout -k 5 15 node screenshot.js #{File.join "http://geocities.gallery", url} #{output_path_png} > /dev/null 2>&1`
    if !File.exist?(output_path_png)
      out "#{url}: NO IMAGE\n"
      write_bad_url url
    else
      #image = MiniMagick::Image.open output_path_png
      #image.resize '640x480'
      #image.format 'jpg'
      #image.quality '90'
      #image.write output_path_jpg
      #FileUtils.rm output_path_png
      out "#{url} -> #{output_path_png}: DONE\n"
    end
  end
end

pool.shutdown
pool.wait_for_termination
