# typo3-arm-docker

A docker image containing Apache, PHP7, MySQL, and Typo3 CMS, compatible with ARM processors (eg. Raspberry Pi)


Kubernetes pod
````yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  namespace: typo3-ns
  name: typo3
spec:
  selector:
    matchLabels:
      app: typo3
  replicas: 1
  template:
    metadata:
      labels:
        app: typo3
    spec:
      containers:
        - name: typo3
          image: sebpiller/typo3
          ports:
            - containerPort: 80
              name: web
          volumeMounts:
            - mountPath: /sites
              subPath: sites
              name: data-volume
      volumes:
        - name: data-volume
          persistentVolumeClaim:
            claimName: typo3-pvc
````

Then run "composer create-project typo3/cms-base-distribution" on the pod to start having fun.
     