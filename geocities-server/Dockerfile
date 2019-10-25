FROM httpd:2-alpine
COPY ./geocities.com.conf /usr/local/apache2/conf/extra/httpd-vhosts.conf
RUN sed -i \
        -e 's/^#\(LoadModule .*mod_speling.so\)/\1/' \
        -e 's/^#\(LoadModule .*mod_sed.so\)/\1/' \
        -e 's/^#\(Include .*httpd-vhosts.conf\)/\1/' \
        conf/httpd.conf
