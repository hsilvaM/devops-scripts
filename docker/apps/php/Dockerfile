FROM hsilv/oracle-php-base:latest

COPY apps/php/php-app/ /var/www/html/

RUN set -eux; \
    sed -i 's/Listen 80/Listen 3001/' /etc/apache2/ports.conf; \
    sed -i 's/<VirtualHost \*:80>/<VirtualHost *:3001>/' /etc/apache2/sites-available/000-default.conf; \
    { \
        echo 'Alias /php /var/www/html'; \
        echo '<Directory /var/www/html>'; \
        echo '    Options Indexes FollowSymLinks'; \
        echo '    AllowOverride All'; \
        echo '    Require all granted'; \
        echo '</Directory>'; \
    } > /etc/apache2/conf-available/php-app.conf; \
    a2enconf php-app; \
    sed -i 's#DocumentRoot /var/www/html#DocumentRoot /var/www/html\n    RedirectMatch ^/$ /php#' /etc/apache2/sites-available/000-default.conf

