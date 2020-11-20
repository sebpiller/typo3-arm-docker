service mysql start

a2enconf 001-typo-cms
service apache2 start
a2ensite 001-typo-cms
service apache2 reload