# Creating Kubernetes Cluster(wordpress deployment
gcloud config set compute/zone [ZONE]

gcloud config set compute/region [REGION]

gcloud container clusters create [CLUSTER-NAME] --num-nodes [# of NODES]

gcloud compute instances list

eval $(minikube docker-env)

kubectl run wordpress --image=tutum/wordpress --port=80 ### images name

kubectl get pods

kubectl get nodes

kubectl expose pod [POD NAME] --name=[SERVICE NAME] --type=LoadBalancer ### to allow traffic from external system

kubectl describe services [SERVICE NAME] ## to check status on service

kubectl set image deployment/[DEPLOYMENT_NAME] [CONTAINER NAME] = [IMAGE NAME]

kubectl get storageclass


# Scaling NODES with the cluster autoscaler
gcloud container clusters create [CLUSTER-NAME] --num-nodes=5 --enable-autoscaling --min-nodes=3 --max-nodes=10 [--zone=[ZONE] \ --project=[PROJECTID]]


# Scalling Pods with Horizontal Pod Autoscaler(HPA)
kubectl autoscale deployment my-app --max=6 --min=4 --cpu-percent=50

kubectl describe hpa [NAME-OF-HPA]

kubectl delete hpa [NAME-OF-HPA]

gcloud container clusters resize [clustername] --node-pool [poolname] --size 5 --region=[region name]

gcloud container clusters update [clustername] --enable-autoscaling --min-nodes 1 --max-nodes 5 --zone [zone] --node-pool [nodepool]


# Kubernetes deployments
kubectl get deployments

kubectl scale deployment [deplyment] --replicas 5

kubectl autoscale deployment [deplyment] --max 10 --min 1 --cpu-percent 80

kubectl delete deployment [deplyment]


# Kubernets services
kubectl get services

kubectl run [servicename] --image=gcr.io/google/samples/hello-app:1.0 --port 8080

kubectl expose deployment [deployment] --type="LoadBalancer"

kubectl delete service [servicename]


# Container registry
gcloud container images list

gcloud container images list --repository gcr.io/google-containers ### google container images



# Sample deployment
gcloud config set compute/zone us-central1-b

gcloud init

gcloud config list

gcloud container clusters create io

gcloud container clusters list

gcloud container clusters get-credentials io --zone us-west1-b --project grossary-195801 ### connect contrainer cluster for kubectl command

kubectl create deployment nginx --image=nginx:1.10.0 #### launch single instance of nginx container

kubectl expose deployment nginx --port 80 --type LoadBalancer #### to create service and expose IP to service

kubectl exec [POD_name] --stdin --tty -c [pod_name] /bin/sh ### to run interactive shell inside [POD]



# Django app deployment
gcloud auth configure-docker

docker build -t gcr.io/${PROJECT_ID}/django:v1 .

docker image list

docker push gcr.io/${PROJECT_ID}/django:v1

gcloud beta container --project "datastore-268122" clusters create "gke1" --zone "us-central1-c"

gcloud container clusters get-credentials gke1

kubectl create deployment django --image=gcr.io/${PROJECT_ID}/django:v1

kubectl expose deployment django --type=LoadBalancer --port 80 --target-port 8000

kubectl set image deployment/django django=gcr.io/${PROJECT_ID}/django:v3 ##### to change version information

