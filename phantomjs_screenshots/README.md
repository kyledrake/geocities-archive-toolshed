# geocities.archive PhantomJS Screenshotter

This lil' script generates the screenshots for the processed geocities archive using PhantomJS.
We've got millions of these go to through, so we're parallelizing the PhantomJS operations,
which are largely IO/wait bound. You may need to adjust the thread count.

You will need to add a /etc/hosts record for www.geocities.com pointing to a server with a copy of
the geocities archive files for the browser to load.

(deps: ruby, imagemagick)

    gem install bundler
    bundle install
    bundle exec ruby capture.rb
