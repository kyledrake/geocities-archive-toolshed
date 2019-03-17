# Case Insensitive Webserver

This is a web server that looks for files to serve in a case insensitive manner.
This server may not be good enough for the Geocities archive, in fact you should assume it isn't. I haven't yet confirmed if mod_speling was configured for case insensitivity or if it was also configured for "one character off" searches. I could see a lot of links to .htm actually being destined for .html files, and not being changed because they worked. The only way to really confirm this is to scan all of the HTML files for it.

Reading:

http://blog.geocities.institute/archives/2948
http://httpd.apache.org/docs/2.2/mod/mod_speling.html

    gem install bundler
    bundle install
    ARCHIVE_PATH=path/to/archive bundle exec ruby app.rb
