apiVersion: apps/v1
kind: Deployment
metadata:
  name: facade
  labels:
    app: facade
    app.kubernetes.io/name: facade
spec:
  selector:
    matchLabels:
      app: facade
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 0
      maxUnavailable: 1
  template:
    metadata:
      labels:
        app: facade
    spec:
      serviceAccountName: ckanserviceaccount
      containers:
        - name: facade
          image: europe-docker.pkg.dev/dft-rsss-findtransptdata-dev/dft-nap/facade:COMMIT_SHA
          resources:
            limits:
               #memory: 512Mi
               #cpu: 750m
            requests:
               #memory: 128Mi
               #cpu: 500m
          ports:
           - name: facade-app
             containerPort: 3000
             protocol: TCP
          readinessProbe:
            tcpSocket:
              port: facade-app
            initialDelaySeconds: 5
            periodSeconds: 10
          livenessProbe:
            httpGet:
              path: /
              port: facade-app
              httpHeaders:
              - name: Accept
                value: "*/*"
            initialDelaySeconds: 15
            periodSeconds: 15
          env:
          - name: CKAN_API_URL
            value: £API_URL
          - name: FACADE_SECRET_KEY
            value: £FACADE_SECRET_KEY
          - name: CKAN_API_KEY
            value: £CKAN_API_KEY
          - name: GOV_NOTIFY_PUBLISHER_REQUEST_TEMPLATE_ID
            value: £GOV_NOTIFY_PUBLISHER_REQUEST_TEMPLATE_ID
          - name: GOV_NOTIFY_PUBLISHER_WELCOME_TEMPLATE_ID
            value: £GOV_NOTIFY_PUBLISHER_WELCOME_TEMPLATE_ID
          - name: GOV_NOTIFY_PUBLISHER_REQUEST_EMAIL_TO
            value: £GOV_NOTIFY_PUBLISHER_REQUEST_EMAIL_TO
          - name: GOV_NOTIFY_CONTACT_PAGE_ADMIN_VIEW_TEMPLATE_ID
            value: £GOV_NOTIFY_CONTACT_PAGE_ADMIN_VIEW_TEMPLATE_ID
          - name: GOV_NOTIFY_CONTACT_PAGE_PUBLISHER_VIEW_TEMPLATE_ID
            value: £GOV_NOTIFY_CONTACT_PAGE_PUBLISHER_VIEW_TEMPLATE_ID
          - name: GOV_NOTIFY_NEW_PUBLISHER_ACCOUNT_REQUEST_TEMPLATE_ID 
            value: £GOV_NOTIFY_NEW_PUBLISHER_ACCOUNT_REQUEST_TEMPLATE_ID
          - name: GOV_NOTIFY_REJECT_DATASET_EMAIL_TO_PUBLISHER
            value: £GOV_NOTIFY_REJECT_DATASET_EMAIL_TO_PUBLISHER
          - name: GOV_NOTIFY_REJECT_PUBLISHER_REQUEST_TEMPLATE_ID
            value: £GOV_NOTIFY_REJECT_PUBLISHER_REQUEST_TEMPLATE_ID
          - name: GOV_NOTIFY_RESET_PASSWORD_TEMPLATE_ID
            value: £GOV_NOTIFY_RESET_PASSWORD_TEMPLATE_ID
          - name: GOV_NOTIFY_KEY
            value: £GOV_NOTIFY_KEY
          - name: GOV_NOTIFY_CONTACT_PAGE_TEMPLATE_ID
            value: £GOV_NOTIFY_CONTACT_PAGE_TEMPLATE_ID
          - name: GOV_NOTIFY_CONTACT_INFO_EMAIL_TO
            value: £GOV_NOTIFY_CONTACT_INFO_EMAIL_TO
          - name: FACADE_SEQUELIZE_URL
            value: £FACADE_SEQUELIZE_URL
          - name: REDIS_HOST
            value: "£REDIS_HOST"
          - name: REDIS_PORT
            value: "£REDIS_PORT"
          - name: GTM_ID 
            value: £GTM_ID
          - name: DOMAIN_NAME
            value: £DOMAIN_NAME
        # <INSTANCE_CONNECTION> here to include your GCP
        # project, the region of your Cloud SQL instance and the name
        # of your Cloud SQL instance. The format is
        # $PROJECT:$REGION:$INSTANCE
        # [START proxy_container]
        - name: cloudsql-proxy
          image: gcr.io/cloudsql-docker/gce-proxy:1.20.0
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
          #  runAsUser: 92  # non-root user
          #  allowPrivilegeEscalation: false
          # [END cloudsql_security_context]
          volumeMounts:
            - name: cloudsql-instance-credentials
              mountPath: /secrets/cloudsql
              readOnly: true
        # [END proxy_container]
      # [START volumes]    
      volumes:
        - name: facade-data
          persistentVolumeClaim:
            claimName: facade-pvc
        - name: cloudsql-instance-credentials
          csi:
            driver: secrets-store.csi.k8s.io
            readOnly: true
            volumeAttributes:
              secretProviderClass: "cloudsql-secrets"    

            
