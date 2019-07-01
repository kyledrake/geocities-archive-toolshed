# frozen_string_literal: true
# Takes output file generated by 002-find-missing-files.sh and uses it to find missing files available on the internet archive.

require 'fileutils'
require 'json'
require 'http'
require 'pry'
require 'concurrent-ruby'

# Documentation for this API: https://archive.org/help/wayback_api.php
# More useful documentation: https://en.wikipedia.org/wiki/Help:Using_the_Wayback_Machine
WAYBACK_AVAILABLE_URL = 'https://archive.org/wayback/available'

if ARGV.length != 3
  puts "usage: 003-restore-missing-files.rb archive_root_path missing-files-output.log checkpoint-file.log"
  exit
end

ARCHIVE_PATH = ARGV[0]
MISSING_FILES_LOG_PATH = ARGV[1]
CHECKPOINT_PATH = ARGV[2]
CONCURRENT_API_CALLS = 100

cp_cnt = 0
cp     = File.exist?(CHECKPOINT_PATH) ? File.read(CHECKPOINT_PATH) : nil
cp_hit = cp.nil?

pool = Concurrent::ThreadPoolExecutor.new(
  min_threads: CONCURRENT_API_CALLS,
  max_threads: CONCURRENT_API_CALLS,
  max_queue:   CONCURRENT_API_CALLS,
  fallback_policy: :caller_runs
)

File.foreach(MISSING_FILES_LOG_PATH) do |line|

  if !cp_hit
    if cp == line
      puts "resuming at #{line}"
      cp_hit = true
    else
      next
    end
  end

  File.write(CHECKPOINT_PATH, line) if cp_cnt%1000==0
  cp_cnt += 1

  begin
    line.gsub! /\?.+$/, ''
    file_path, file_url = line.split "\t"

    if File.extname(file_path) == ''
      file_path = File.join file_path, 'index.html'
    end
  rescue ArgumentError => e
    next if e.message =~ /invalid byte sequence/i
    raise e
  end
  file_url.strip!
  next if File.exist? file_path

  pool.post {
     api_res = JSON.parse HTTP.get(WAYBACK_AVAILABLE_URL, params: {url: file_url})
     closest = api_res['archived_snapshots']['closest']
     next if closest.nil?
     datetime_string = closest['url'].match(/\/web\/(\d+)/).captures.first
     raw_version_url = closest['url'].sub datetime_string, datetime_string+'id_'
     res = HTTP.get raw_version_url
     last_modified = Time.parse res.headers['X-Archive-Orig-Last-Modified']
     FileUtils.mkdir_p File.extname(file_path)
     IO.binwrite file_path, res
     FileUtils.touch file_path, mtime: last_modified
     puts "restored #{file_path} #{file_url}"
  }
end

at_exit {
  pool.shutdown
  pool.wait_for_termination
}

`find #{ARCHIVE_PATH} -name "*.geo" -type f -delete`

=begin

This script generated a lot of strange sites that ended with .geo, but many of the
files were actually directories with an index.html so this was not restored properly.
I need to come back to this later, but I'm moving on for now. This is the list that was deleted:

megangirl.geo
randrews.geo
nealmoorhouse.geo
magzilla.geo
phonolite.geo
rapidray.geo
velmont.geo
tjrand.geo
rennsport.geo
hulaman.geo
zouli.geo
entrebat.geo
lacey.geo
djbaby.geo
joseac.geo
yellowlabs.geo
prizner.geo
pekehaven.geo
inetkitten.geo
parakenings.geo
starrtaylore.geo
derock.geo
crimsonempire.geo
subhashn.geo
murthy.geo
ilbo.geo
pitstop.geo
ophelialost.geo
Mehdi80.geo
ridgetop.geo
sejor.geo
jlopp.geo
probstat.geo
terimurphy.geo
cathyl494.geo
gameset.geo
ivelisseh.geo
wwwbr.geo
each.geo
magicmommy.geo
lindayang.geo
robilyn.geo
laguia.geo
venkarel.geo
guri_lady.geo
hammerbolt.geo
grandcayman.geo
anastasia11.geo
jmong.geo
fantomas65.geo
azappa.geo
togi.geo
TStodden.geo
svenolov.geo
navygir1y.geo
jellybaby.geo
vegetrunks.geo
deafbear.geo
marcyp.geo
lil_mo.geo
jennyhawkins.geo
ded777.geo
jodeman.geo
brally.geo
trulibra.geo
pivoine.geo
zozi.geo
spoza.geo
ucpd.geo
pikkun.geo
hoovers.geo
kingjesus.geo
osalinas.geo
starfly.geo
agarry.geo
ldgolden.geo
rinor.geo
parrilla.geo
ewings.geo
ballinasloe.geo
=end
