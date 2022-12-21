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
  #    serviceAccountName: ckan-serviceaccount
      containers:
        - name: facade
          image:europe-docker.pkg.dev/dft-rsss-findtransptdata-dev/dft-nap/facade:$SHORT_SHA
#          securityContext:
#            runAsNonRoot: true
#            runAsUser: 92  
          resources:
            limits:
               memory: 300Mi
            requests:
               memory: 150Mi
          ports:
           - name: facade-app
             containerPort: 3000
             protocol: TCP
          env:
          - name: CKAN_API_URL
            value: _CKAN_API_URL
          - name: FACADE_SECRET_KEY
            value: _FACADE_SECRET_KEY
          - name: CKAN_API_KEY
            value: _CKAN_API_KEY
