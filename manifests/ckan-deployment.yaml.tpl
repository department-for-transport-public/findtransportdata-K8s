apiVersion: apps/v1
kind: Deployment
metadata:
  name: ckan
  labels:
    app: ckan
    app.kubernetes.io/name: ckan
spec:
  selector:
    matchLabels:
      app: ckan
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 0
      maxUnavailable: 1
  template:
    metadata:
      labels:
        app: ckan
    spec:
      serviceAccountName: ckanserviceaccount
      containers:
        - name: ckan
          image: europe-docker.pkg.dev/dft-rsss-findtransptdata-dev/dft-nap/ckan_297:COMMIT_SHA
          securityContext:
            runAsNonRoot: true
            runAsUser: 92
          resources:
            limits:
               memory: 512Mi
            requests:
               memory: 256Mi
          ports:
            - name: ckan-app  
              containerPort: 5000
          readinessProbe:
            tcpSocket:
              port: ckan-app
            initialDelaySeconds: 15
            periodSeconds: 15
          livenessProbe:
            httpGet:
              path: /api/3/action/status_show
              port: ckan-app
              httpHeaders:
              - name: Accept
                value: "*/*"
            initialDelaySeconds: 15
            periodSeconds: 25
            timeoutSeconds: 10
          env:
          - name: CKAN_SITE_ID
            value: "default"
          - name: CKAN_SITE_URL
            value: _CKAN_SITE_URL
          - name: CKAN_PORT
            value: "5000"
          - name:  CKAN_MAX_UPLOAD_SIZE_MB
            value: "10"
          - name: CKAN__PLUGINS
            value: "envvars image_view text_view recline_view datastore datapusher nap_theme"
          - name: CKAN_SYSADMIN_NAME
            value: _CKAN_SYSADMIN_NAME
          - name: CKAN_SYSADMIN_PASSWORD
            value: _CKAN_SYSADMIN_PASSWORD
          - name: CKAN_SYSADMIN_EMAIL
            value: _CKAN_SYSADMIN_EMAIL
          - name: CKAN_SQLALCHEMY_URL
            value: _CKAN_SQLALCHEMY_URL
          - name: CKAN_SOLR_URL
            value: "http://solr-headless:8983/solr/ckan"
#          - name: MAINTENANCE_MODE
#            value: "true"
          - name: CKAN_DATASTORE_WRITE_URL
            value: _CKAN_DATASTORE_WRITE_URL
          - name: CKAN_DATASTORE_READ_URL
            value: _CKAN_DATASTORE_READ_URL
          - name: CKAN__STORAGE_PATH
            value: "/var/lib/ckan"
          - name: CKAN_DATASETS_PER_PAGE
            value: "50"
          - name: FTD_TEST
            value: _FTD_TEST_VAR
          - name: GTM_ID
            value: _GTM_ID
#          - name: CKAN_WEBASSETS_PATH
#            value: "/srv/app/data/webassets"
# Datapusher
          - name: CKAN__DATAPUSHER__URL
            value: "http://datapusher:8000"
          - name: CKAN__DATAPUSHER__CALLBACK_URL_BASE
            value: "http://ckan:5000/"
# Redis
          - name: CKAN__REDIS__URL
            value: _CKAN_REDIS_URL
          volumeMounts:
          - name: ckan-data
            mountPath: /var/lib/ckan
            readOnly: false
        # <INSTANCE_CONNECTION> here to include your GCP
        # project, the region of your Cloud SQL instance and the name
        # of your Cloud SQL instance. The format is
        # $PROJECT:$REGION:$INSTANCE
        # [START proxy_container]
        - name: cloudsql-proxy
          image: gcr.io/cloudsql-docker/gce-proxy:1.20
          resources:
            limits:
              memory: 100Mi
            requests:
              memory: 100Mi
          command: ["/cloud_sql_proxy",
                    "-instances=$(INSTANCE_CONNECTION)=tcp:5432",
                    "-credential_file=/secrets/cloudsql/key.json"]
          env:
          - name: INSTANCE_CONNECTION
            valueFrom:
              configMapKeyRef:
                key: connectionname
                name: connectionname
          # [START cloudsql_security_context]
          securityContext:
            runAsUser: 2  # non-root user
            allowPrivilegeEscalation: false
          # [END cloudsql_security_context]
          volumeMounts:
            - name: cloudsql-instance-credentials
              mountPath: /secrets/cloudsql
              readOnly: true
        # [END proxy_container]
      # [START volumes]
      volumes:
        - name: ckan-data
          persistentVolumeClaim:
            claimName: ckan-pvc
        - name: cloudsql-instance-credentials
          csi:
            driver: secrets-store.csi.k8s.io
            readOnly: true
            volumeAttributes:
              secretProviderClass: "cloudsql-secrets"
      # [END volumes]
      initContainers:
      - name: set-volume-ownership
        image: busybox:1.34
        resources:
          limits:
            memory: 100Mi
          requests:
            memory: 100Mi
        command: ["sh", "-c", "chown -R 92:92 /var/lib/ckan"] # 92 is the uid and gid of ckan user/group
        volumeMounts:
        - name: ckan-data
          mountPath: /var/lib/ckan
          readOnly: false
