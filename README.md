# typo3-arm-docker

A docker image containing Apache, PHP7, MySQL, and Composer, compatible with ARM processors (eg. Raspberry Pi), aimed at 
installing Typo3 CMS.

Kubernetes deployment sample:
````yaml
###
## Typo3 installation, with Bootstrap.
##
## POST INSTALLATION ACTIONS:
##   - after the first launch, connect to the pod:
##     - run "/usr/bin/mysql_secure_installation" to configure MySQL for production use.
##     - log to mysql with "mysql -u root -p" and call the sql statements:
##       - CREATE DATABASE typo3 CHARACTER SET utf8 COLLATE utf8_bin;
##       - CREATE USER typo3_user IDENTIFIED BY 'password';
##       - GRANT ALL PRIVILEGES ON typo3.* TO typo3_user;
##       - FLUSH PRIVILEGES;
##     - run "touch /var/www/typo-cms/public/FIRST_INSTALL" to tell Typo3 to init the installation process
##     - edit /var/www/typo-cms/composer.json, add
##           , "bk2k/bootstrap-package": "^11.0.2"
##           , "aimeos/aimeos-typo3": "^20.10.2"
##       to the require section, then launch "su -l www-data -s /bin/bash -c 'cd /var/www/typo-cms && composer update'"
##     - if using aimeos, then add
#        "scripts": {
#          "post-install-cmd": [
#            "Aimeos\\Aimeos\\Custom\\Composer::install"
#          ],
#          "post-update-cmd": [
#            "Aimeos\\Aimeos\\Custom\\Composer::install"
#          ]
#        }
##       to the compose.json
##     - run typo3cms database:updateschema "*.add,*.change"
##     - access "http://<ip>:8910" with your browser to begin the installation
###
apiVersion: v1
kind: Namespace
metadata:
  name: spidybox-web-ns
---
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: spidybox-web-ns
  name: typo-cms-apache-config
data:
  conf-001-typo-cms.conf: |
    ServerName spidybox.ch
  vhost-001-typo-cms.conf: |
    <VirtualHost *:*>
        # Typo3 tweaks
        php_admin_value upload_max_filesize 8M
        php_admin_value max_execution_time 300
        php_admin_value max_input_vars 2000
        php_admin_value memory_limit 512M
        php_admin_value safe_mode_exec_dir /var/www/typo-cms/execdir/
        php_flag register_argc_argv off
        php_flag magic_quotes_gpc off
        php_value variables_order GPCS

        # enable safe PHP operation
        php_admin_value safe_mode on
        php_admin_value safe_mode_gid on

        php_flag register_globals off

        ServerName www.spidybox.ch
        ServerAlias *.spidybox.ch

        DocumentRoot "/var/www/typo-cms/public"

        CustomLog /var/log/apache2/typo3.log vhost_combined
        ErrorLog /var/log/apache2/typo3_error.log

        <DirectoryMatch /var/www/typo-cms/>
            DirectoryIndex index.php index.html

            # TYPO3 needs files shared between different instances. These are
            # symlinked into the document root directory. The following
            # directive enables that apache follows the symlinks.
            Options +FollowSymLinks

            Order allow,deny
            Allow from all

            ### Begin: PHP optimisation ###
            <IfModule mod_mime.c>

              RemoveType .html .htm
              <FilesMatch ".+\.html?$">
                  AddType text/html .html
                  AddType text/html .htm
              </FilesMatch>

              RemoveType .svg .svgz
              <FilesMatch ".+\.svgz?$">
                  AddType image/svg+xml .svg
                  AddType image/svg+xml .svgz
              </FilesMatch>

            </IfModule>
            ### End: PHP optimisation ###

            ### Begin: Rewrite stuff ###
            <IfModule mod_rewrite.c>

                # Enable URL rewriting
                RewriteEngine On

                # To assist in debugging rewriting, you could use these lines
                # DON'T enable it for production!
                #RewriteLog /var/log/apache/rewrite.log
                #RewriteLogLevel 9

                # Stop rewrite processing if we are in the typo3/ directory
                RewriteRule ^/(typo3|typo3temp|typo3conf|t3lib|fileadmin|uploads)/ - [L]

                # Redirect http://mysite/cms/typo3 to http://mysite/cms/typo3/index_re.php
                # and stop the rewrite processing
                RewriteRule ^/typo3$ /typo3/index_re.php [L]

                # If the file/symlink/directory does not exist => Redirect to index.php
                RewriteCond %{REQUEST_FILENAME} !-f
                RewriteCond %{REQUEST_FILENAME} !-d
                RewriteCond %{REQUEST_FILENAME} !-l

                # Main URL rewriting.
                RewriteRule .* /index.php [L]

            </IfModule>
            ### End: Rewrite stuff ###
        </DirectoryMatch>
    </VirtualHost>
---
kind: PersistentVolume
apiVersion: v1
metadata:
  namespace: spidybox-web-ns
  name: spidybox-web-pv
  labels:
    type: local
spec:
  local:
    path: /data/spidybox-web
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteOnce
  nodeAffinity:
    required:
      nodeSelectorTerms:
        - matchExpressions:
            - key: node-role.kubernetes.io/worker
              operator: In
              values:
                - worker
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  namespace: spidybox-web-ns
  name: spidybox-web-pvc
  labels:
    app.kubernetes.io/name: spidybox-web-pv
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  namespace: spidybox-web-ns
  name: typo3-dep
spec:
  selector:
    matchLabels:
      name: typo3
  replicas: 1
  template:
    metadata:
      labels:
        name: typo3
    spec:
      initContainers:
        - image: sebpiller/typo3:latest
          name: init-mysql-default-database
          command:
            - /bin/sh
            - -c
            # if and only if the database has not been initialized yet
            - \[ "$(ls -A /var/lib/mysql)" ] && exit 0; mysql_install_db; exit 0;
          volumeMounts:
            - mountPath: /var/lib/mysql
              subPath: mysql-data
              name: data-volume
        - image: sebpiller/typo3:latest
          name: init-typo3-site
          command:
            - /bin/sh
            - -c
            # if and only if the typo3 site has not been initialized yet
            - \[ "$(ls -A /var/www/typo-cms)" ] && exit 0; su -l www-data -s /bin/bash -c 'cd /var/www && composer -n create-project typo3/cms-base-distribution typo-cms'; exit 0;
          volumeMounts:
            - mountPath: /var/www
              subPath: apache-sites
              name: data-volume
      containers:
        - name: typo-cms-web
          image: sebpiller/typo3:latest
          command:
            - /bin/sh
            - -c
            - service mysql start && a2enconf 001-typo-cms && service apache2 start && a2dissite 000-default && a2ensite 001-typo-cms && service apache2 reload && sleep infinity
          ports:
            - containerPort: 80
              name: web
          volumeMounts:
            - mountPath: /etc/apache2/sites-available/001-typo-cms.conf
              subPath: vhost-001-typo-cms.conf
              name: apache-config
            - mountPath: /etc/apache2/conf-available/001-typo-cms.conf
              subPath: conf-001-typo-cms.conf
              name: apache-config
            - mountPath: /var/www
              subPath: apache-sites
              name: data-volume
            - mountPath: /var/lib/mysql
              subPath: mysql-data
              name: data-volume
            - mountPath: /public
              subPath: typo3-public
              name: data-volume
            - mountPath: /config
              subPath: typo3-config
              name: data-volume
      volumes:
        - name: data-volume
          persistentVolumeClaim:
            claimName: spidybox-web-pvc
        - name: apache-config
          configMap:
            name: typo-cms-apache-config
---
apiVersion: v1
kind: Service
metadata:
  namespace: spidybox-web-ns
  name: typo-cms-web-svc
spec:
  type: LoadBalancer
  ports:
    - port: 8910
      targetPort: web
      name: lb-web
  selector:
    name: typo3
---
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  namespace: spidybox-web-ns
  name: typo-cms-ingress
  annotations:
    kubernetes.io/ingress.class: "traefik"
spec:
  rules:
    - host: www.spidybox.ch
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              serviceName: typo-cms-web-svc
              servicePort: lb-web
---
````
