# typo3-arm-docker

A docker image containing Apache, PHP7, MySQL, and Composer, compatible with ARM processors (eg. Raspberry Pi), aimed at 
installing Typo3 CMS.

Kubernetes pod
````yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  namespace: my-ns
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
          name: init-typo3-site
          command:
            - /bin/sh
            - -c
            # if and only if the site has not been initialized yet
            - \[ "$(ls -A /sites)" ] && exit 0; cd /sites; composer -n create-project typo3/cms-base-distribution typo3; exit 0;
          volumeMounts:
            - mountPath: /sites
              subPath: typo3-sites
              name: data-volume
      containers:
        - name: spidybox-web
          image: sebpiller/typo3:latest
          ports:
            - containerPort: 80
              name: web
          volumeMounts:
            - mountPath: /etc/apache2/apache2.conf
              subPath: apache2.conf
              name: apache-config
            - mountPath: /etc/apache2/sites-available/001-spidybox-web.conf
              subPath: 001-spidybox-web.conf
              name: apache-config
            - mountPath: /sites
              subPath: typo3-sites
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
            name: spidybox-apache-config
---
````
