# About

This lab is primer intended to demystify running Spark on Dataproc on GKE with a minimum viable Spark application.<br> 
It includes the foundational setup - the network, subnet, Dataproc Persistent History Server.<br>


In this lab, we will-
1. Run the foundational setup for Dataproc - APIs, org policies, buckets, the network, subnet, (optional) Dataproc Persistent History Server, (optional) Dataproc Metastore Service
2. Run the foundational setup for GKE  
3. Create a basic Dataproc on GKE cluster.
4. Run a basic Spark application on it
5. Review logging


## 1. Foundational setup for Dataproc

### 1.1. Variables

```
PROJECT_ID=`gcloud config list --format "value(core.project)" 2>/dev/null`
PROJECT_NBR=`gcloud projects describe $PROJECT_ID | grep projectNumber | cut -d':' -f2 |  tr -d "'" | xargs`
PROJECT_NAME=`gcloud projects describe ${PROJECT_ID} | grep name | cut -d':' -f2 | xargs`
YOUR_ACCOUNT_NAME=`gcloud auth list --filter=status:ACTIVE --format="value(account)"`
ORG_ID=`gcloud organizations list --format="value(name)"`
LOCATION=us-central1
ZONE=us-central1-a

# The public IP address of your Cloud Shell, to add to the firewall
MY_IP_ADDRESS=`curl -s checkip.dyndns.org | sed -e 's/.*Current IP Address: //' -e 's/<.*$//'`
echo $MY_IP_ADDRESS

UMSA="lab-sa"
UMSA_FQN=$UMSA@$PROJECT_ID.iam.gserviceaccount.com

SPARK_BUCKET=dataproc-spark-bucket-$PROJECT_NBR
SPARK_BUCKET_FQN=gs://$SPARK_BUCKET-bucket
PERSISTENT_HISTORY_SERVER_BUCKET_FQN=gs://dataproc-phs-bucket-$PROJECT_NBR
PERSISTENT_HISTORY_SERVER_NM=dataproc-phs-$PROJECT_NBR

VPC_NM=vpc-$PROJECT_NBR
SPARK_SUBNET_NM=spark-snet
```

### 1.2. Enable APIs

Enable APIs of services in scope for the lab, and their dependencies.<br>
Paste these and run in cloud shell-
```
gcloud services enable dataproc.googleapis.com
gcloud services enable orgpolicy.googleapis.com
gcloud services enable compute.googleapis.com
gcloud services enable container.googleapis.com
gcloud services enable containerregistry.googleapis.com
gcloud services enable bigquery.googleapis.com 
gcloud services enable storage.googleapis.com
gcloud services enable metastore.googleapis.com
gcloud services enable artifactregistry.googleapis.com
```

<br><br>

<hr>

### 1.3. Update Organization Policies

The organization policies include the superset applicable for all flavors of Dataproc, required in Argolis.<br>
Paste these and run in cloud shell-

#### 1.3.a. Relax require OS Login
```
rm -rf os_login.yaml

cat > os_login.yaml << ENDOFFILE
name: projects/${PROJECT_ID}/policies/compute.requireOsLogin
spec:
  rules:
  - enforce: false
ENDOFFILE

gcloud org-policies set-policy os_login.yaml 

rm os_login.yaml
```

#### 1.3.b. Disable Serial Port Logging

```
rm -rf disableSerialPortLogging.yaml

cat > disableSerialPortLogging.yaml << ENDOFFILE
name: projects/${PROJECT_ID}/policies/compute.disableSerialPortLogging
spec:
  rules:
  - enforce: false
ENDOFFILE

gcloud org-policies set-policy disableSerialPortLogging.yaml 

rm disableSerialPortLogging.yaml
```

#### 1.3.c. Disable Shielded VM requirement

```
rm -rf shieldedVm.yaml 

cat > shieldedVm.yaml << ENDOFFILE
name: projects/$PROJECT_ID/policies/compute.requireShieldedVm
spec:
  rules:
  - enforce: false
ENDOFFILE

gcloud org-policies set-policy shieldedVm.yaml 

rm shieldedVm.yaml 
```

#### 1.3.d. Disable VM can IP forward requirement

```
rm -rf vmCanIpForward.yaml

cat > vmCanIpForward.yaml << ENDOFFILE
name: projects/$PROJECT_ID/policies/compute.vmCanIpForward
spec:
  rules:
  - allowAll: true
ENDOFFILE

gcloud org-policies set-policy vmCanIpForward.yaml

rm vmCanIpForward.yaml
```

#### 1.3.e. Enable VM external access

```
rm -rf vmExternalIpAccess.yaml

cat > vmExternalIpAccess.yaml << ENDOFFILE
name: projects/$PROJECT_ID/policies/compute.vmExternalIpAccess
spec:
  rules:
  - allowAll: true
ENDOFFILE

gcloud org-policies set-policy vmExternalIpAccess.yaml

rm vmExternalIpAccess.yaml
```

#### 1.3.f. Enable restrict VPC peering

```
rm -rf restrictVpcPeering.yaml

cat > restrictVpcPeering.yaml << ENDOFFILE
name: projects/$PROJECT_ID/policies/compute.restrictVpcPeering
spec:
  rules:
  - allowAll: true
ENDOFFILE

gcloud org-policies set-policy restrictVpcPeering.yaml

rm restrictVpcPeering.yaml
```

<br><br>

<hr>


### 1.4. Create a User Managed Service Account (UMSA) & grant it requisite permissions

The User Managed Service Account (UMSA) is to avoid using default Google Managed Service Accounts where supported for tighter security and control.<br>
Paste these and run in cloud shell-

#### 1.4.a. Create UMSA
```
gcloud iam service-accounts create ${UMSA} \
    --description="User Managed Service Account for the project" \
    --display-name=$UMSA 
```
 
<br><br>

#### 1.4.b. Grant IAM permissions for the UMSA

```
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member=serviceAccount:${UMSA_FQN} \
    --role=roles/iam.serviceAccountUser
    
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member=serviceAccount:${UMSA_FQN} \
    --role=roles/iam.serviceAccountTokenCreator 
    
gcloud projects add-iam-policy-binding $PROJECT_ID --member=serviceAccount:$UMSA_FQN \
--role="roles/bigquery.dataEditor"


gcloud projects add-iam-policy-binding $PROJECT_ID --member=serviceAccount:$UMSA_FQN \
--role="roles/bigquery.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID --member=serviceAccount:$UMSA_FQN \
--role="roles/dataproc.worker"

gcloud projects add-iam-policy-binding $PROJECT_ID --member=serviceAccount:$UMSA_FQN \
--role="roles/storage.objectCreator"

gcloud projects add-iam-policy-binding $PROJECT_ID --member=serviceAccount:$UMSA_FQN \
--role="roles/dataproc.admin"

```
<br>

#### 1.4.c. Grant permissions for the lab attendee (yourself)
Paste these and run in cloud shell-
```
gcloud iam service-accounts add-iam-policy-binding \
    ${UMSA_FQN} \
    --member="user:${YOUR_ACCOUNT_NAME}" \
    --role="roles/iam.serviceAccountUser"
    
gcloud iam service-accounts add-iam-policy-binding \
    ${UMSA_FQN} \
    --member="user:${YOUR_ACCOUNT_NAME}" \
    --role="roles/iam.serviceAccountTokenCreator"
    
``` 
<br><br>

<hr>

### 1.5. Create VPC, Subnets and Firewall Rules

Dataproc is a VPC native service, therefore needs a VPC subnet.<br>
Paste these and run in cloud shell-

#### 1.5.a. Create VPC

```
gcloud compute networks create $VPC_NM \
--project=$PROJECT_ID \
--subnet-mode=custom \
--mtu=1460 \
--bgp-routing-mode=regional
```

<br><br>

#### 1.5.b. Create subnet & firewall rules for Dataproc - GCE

Dataproc serverless Spark needs intra subnet open ingress. <br>
Paste these and run in cloud shell-
```
SPARK_SUBNET_CIDR=10.0.0.0/16

gcloud compute networks subnets create $SPARK_SUBNET_NM \
 --network $VPC_NM \
 --range $SPARK_SUBNET_CIDR  \
 --region $LOCATION \
 --enable-private-ip-google-access \
 --project $PROJECT_ID 
 
gcloud compute --project=$PROJECT_ID firewall-rules create allow-intra-$SPARK_SUBNET_NM \
--direction=INGRESS \
--priority=1000 \
--network=$VPC_NM \
--action=ALLOW \
--rules=all \
--source-ranges=$SPARK_SUBNET_CIDR

gcloud compute firewall-rules create allow-ssh-$SPARK_SUBNET_NM \
--project=$PROJECT_ID \
--network=$VPC_NM \
--direction=INGRESS \
--priority=65534 \
--source-ranges=0.0.0.0/0 \
--action=ALLOW \
--rules=tcp:22

```

<br><br>

<hr>

#### 1.5.c. Create subnet & firewall rules for Dataproc - PSHS 
Further in the lab, we will create a persistent Spark History Server where the logs for serverless Spark jobs can be accessible beyond 24 hours (default without). <br>
Paste these and run in cloud shell-

```
SPARK_CATCH_ALL_SUBNET_CIDR=10.6.0.0/24
SPARK_CATCH_ALL_SUBNET_NM=spark-catch-all-snet

gcloud compute networks subnets create $SPARK_CATCH_ALL_SUBNET_NM \
 --network $VPC_NM \
 --range $SPARK_CATCH_ALL_SUBNET_CIDR \
 --region $LOCATION \
 --enable-private-ip-google-access \
 --project $PROJECT_ID 
 
gcloud compute --project=$PROJECT_ID firewall-rules create allow-intra-$SPARK_CATCH_ALL_SUBNET_NM \
--direction=INGRESS \
--priority=1000 \
--network=$VPC_NM \
--action=ALLOW \
--rules=all \
--source-ranges=$SPARK_CATCH_ALL_SUBNET_CIDR
```

<hr>

#### 1.5.d. Grant access to your IP address

```
MY_IP_ADDRESS=`curl -s checkip.dyndns.org | sed -e 's/.*Current IP Address: //' -e 's/<.*$//'`
echo $MY_IP_ADDRESS


MY_FIREWALL_RULE="allow-me-to-ingress-into-vpc"

gcloud compute firewall-rules delete $MY_FIREWALL_RULE

gcloud compute --project=$PROJECT_ID firewall-rules create $MY_FIREWALL_RULE --direction=INGRESS --priority=1000 --network=$VPC_NM --action=ALLOW --rules=all --source-ranges="$MY_IP_ADDRESS/32"

```
 
<br><br>

<hr>

### 1.6. [OPTIONAL] Create common Persistent Spark History Server

A common Persistent Spark History Server can be leveraged across Dataproc clusters and Dataproc serverless for log persistence/retention and providing support personnel the familiar Spark UI for Spark applications that were run, even after ephemeral clusters and jobs have completed.<br>
Docs: https://cloud.google.com/dataproc/docs/concepts/jobs/history-server<br>

Run the command below to provision-
```
gsutil mb -p $PROJECT_ID -c STANDARD -l $LOCATION -b on $PERSISTENT_HISTORY_SERVER_BUCKET_FQN

gcloud dataproc clusters create $PERSISTENT_HISTORY_SERVER_NM \
    --single-node \
    --region=$LOCATION \
    --image-version=1.4-debian10 \
    --enable-component-gateway \
    --properties="dataproc:job.history.to-gcs.enabled=true,spark:spark.history.fs.logDirectory=$PERSISTENT_HISTORY_SERVER_BUCKET_FQN/*/spark-job-history,mapred:mapreduce.jobhistory.read-only.dir-pattern=$PERSISTENT_HISTORY_SERVER_BUCKET/*/mapreduce-job-history/done" \
    --service-account=$UMSA_FQN \
--single-node \
--subnet=projects/$PROJECT_ID/regions/$LOCATION/subnetworks/$SPARK_CATCH_ALL_SUBNET_NM
```
<br><br>

<hr>

### 1.7. [OPTIONAL] Create common Dataproc Metastore Service

A common Dataproc Metastore Service can be leveraged across clusters and serverless for Hive metadata.<br>
This service does not support BYO subnet currently.<br>

Run the command below to provision-
```
gcloud metastore services create $DATAPROC_METASTORE_SERVICE_NM \
    --location=$LOCATION \
    --port=9083 \
    --tier=Developer \
    --hive-metastore-version=3.1.2 \
    --impersonate-service-account=$UMSA_FQN \
    --network=$VPC_NM
```
<br><br>

This takes about 30 minutes to create.

<hr>


## 2. Foundational setup for GKE

### 2.1. Install kubectl
In Cloud Shell, lets install kubectl-
```
sudo apt-get install kubectl
```

Then check the version-
```
kubectl version
```

### 2.2. Install required plugins/check version
kubectl and other Kubernetes clients require an authentication plugin, gke-gcloud-auth-plugin, which uses the Client-go Credential Plugins framework to provide authentication tokens to communicate with GKE clusters.

```
gke-gcloud-auth-plugin --version
```

### 2.3. Create an account for Docker if you dont have one already, and sign-in to Docker on Cloud Shell
This is helpful when creating custom images.

Get an account-
https://docs.docker.com/get-docker/

Sign-in to Docker from Cloud Shell--
```
docker login --username <your docker-username>
```


### 2.4. Create a bucket for use by dataproc on GKE

Paste in Cloud Shell-
```
DPGKE_LOG_BUCKET=dpgke-dataproc-bucket-${PROJECT_NBR}-logs

gcloud storage buckets create gs://$DPGKE_LOG_BUCKET --project=$PROJECT_ID --location=$LOCATION
```

### 2.5. Create a base GKE cluster

Paste in Cloud Shell-
```
# Set variables.
PROJECT_ID=`gcloud config list --format "value(core.project)" 2>/dev/null`
PROJECT_NBR=`gcloud projects describe $PROJECT_ID | grep projectNumber | cut -d':' -f2 |  tr -d "'" | xargs`
GKE_CLUSTER_NAME=dataproc-gke-base-${PROJECT_NBR}
VPC_NM=vpc-$PROJECT_NBR
SPARK_SUBNET=spark-snet
PERSISTENT_HISTORY_SERVER_NM=dataproc-phs-${PROJECT_NBR}
REGION=us-central1
ZONE=us-central1-a
GSA="${PROJECT_NBR}-compute@developer.gserviceaccount.com"
MACHINE_SKU="n2d-standard-4"
UMSA="lab-sa"
UMSA_FQN="${UMSA}@${PROJECT_ID}.iam.gserviceaccount.com"

# Create a GKE cluster
gcloud container clusters create \
  --project "${PROJECT_ID}" \
  --region "${REGION}" \
  "${GKE_CLUSTER_NAME}" \
  --autoscaling-profile optimize-utilization \
  --workload-pool "${PROJECT_ID}.svc.id.goog" \
  --machine-type "${MACHINE_SKU}" \
  --enable-autoscaling \
  --enable-image-streaming \
  --network $VPC_NM \
  --subnetwork $SPARK_SUBNET \
  --num-nodes 2 \
  --min-nodes 0 \
  --max-nodes 2 \
  --local-ssd-count 2 \
  --service-account ${UMSA_FQN}
```

### 2.6. Get credentials to connect to the GKE cluster

Paste in Cloud Shell-
```
gcloud container clusters get-credentials ${GKE_CLUSTER_NAME} --region $REGION
```

### 2.7. Connect to the cluster and list entities created

#### 2.7.1. Namespaces

Paste in Cloud Shell-
```
kubectl get namespaces
```

Here is the author's output-
```
----INFORMATIONAL----
NAME              STATUS   AGE
default           Active   8h
kube-node-lease   Active   8h
kube-public       Active   8h
kube-system       Active   8h
----INFORMATIONAL----
```

#### 2.7.2. Node pools

After creation of the GKE cluster in our lab, there should only be one node pool.

Paste in Cloud Shell-
```
kubectl get nodes -L cloud.google.com/gke-nodepool | grep -v GKE-NODEPOOL | awk '{print $6}' | sort | uniq -c | sort -r
```
Here is the author's output-
```
----INFORMATIONAL----
      1 default-pool
----INFORMATIONAL----
```

#### 2.7.3. Nodes

Paste in Cloud Shell-
```
kubectl get nodes -L cloud.google.com/gke-nodepool
```
Here is the author's output-
```
----INFORMATIONAL----
NAME                                                  STATUS   ROLES    AGE   VERSION           GKE-NODEPOOL
gke-dataproc-gke-base-42-default-pool-aa627942-s50g   Ready    <none>   8h    v1.25.8-gke.500   default-pool
----INFORMATIONAL----
```


### 2.8. Grant requisite permissions to Dataproc agent

Paste in Cloud Shell-
```
gcloud projects add-iam-policy-binding \
  --role roles/container.admin \
  --member "serviceAccount:service-${PROJECT_NBR}@dataproc-accounts.iam.gserviceaccount.com" \
  "${PROJECT_ID}"
```

### 2.9. Grant permissions for the User Managed Service Account to work with GKE and Kubernetes SAs

Run the following commands to assign necessary Workload Identity permissions to the user managed service account. <br>

```
DPGKE_NAMESPACE="dpgke-$PROJECT_NBR" 

#1. Assign your User Managed Service Account the dataproc.worker role to allow it to act as agent
gcloud projects add-iam-policy-binding \
    --role=roles/dataproc.worker \
    --member="serviceAccount:${UMSA_FQN}" \
    "${PROJECT_ID}"

#2. Assign the "agent" Kubernetes Service Account the iam.workloadIdentityUser role to allow it to act as your User Managed Service Account
gcloud iam service-accounts add-iam-policy-binding \
    "${UMSA_FQN}" \
    --member="serviceAccount:${PROJECT_ID}.svc.id.goog[${DPGKE_NAMESPACE}/agent]" \
    --role=roles/iam.workloadIdentityUser 
    
#3. Grant the "spark-driver" Kubernetes Service Account the iam.workloadIdentityUser role to allow it to act as your User Managed Service Account
gcloud iam service-accounts add-iam-policy-binding \
     "${UMSA_FQN}" \
    --member="serviceAccount:${PROJECT_ID}.svc.id.goog[${DPGKE_NAMESPACE}/spark-driver]" \
    --role=roles/iam.workloadIdentityUser 

#4. Grant the "spark-executor" Kubernetes Service Account the iam.workloadIdentityUser role to allow it to act as your User Managed Service Account
gcloud iam service-accounts add-iam-policy-binding \
    "${UMSA_FQN}" \
    --member="serviceAccount:${PROJECT_ID}.svc.id.goog[${DPGKE_NAMESPACE}/spark-executor]" \
    --role=roles/iam.workloadIdentityUser 
```

<hr>

## 3. Create a basic Dataproc virtual cluster on GKE & submit a Spark job to it

### 3.1. Create a basic Dataproc virtual cluster on GKE
```
# Variables
PROJECT_ID=`gcloud config list --format "value(core.project)" 2>/dev/null`
PROJECT_NBR=`gcloud projects describe $PROJECT_ID | grep projectNumber | cut -d':' -f2 |  tr -d "'" | xargs`
GKE_CLUSTER_NAME=dataproc-gke-base-${PROJECT_NBR}
DP_CLUSTER_NAME="dpgke-cluster-static-$PROJECT_NBR"
DPGKE_NAMESPACE="dpgke-$PROJECT_NBR"
DPGKE_CONTROLLER_POOLNAME="dpgke-pool-default"
DPGKE_DRIVER_POOLNAME="dpgke-pool-driver"
DPGKE_EXECUTOR_POOLNAME="dpgke-pool-executor"
DPGKE_LOG_BUCKET=dpgke-dataproc-bucket-${PROJECT_NBR}-logs
UMSA=lab-sa
UMSA_FQN="${UMSA}@${PROJECT_ID}.iam.gserviceaccount.com"
REGION="us-central1"
ZONE=${REGION}-a

# Get credentials to the GKE cluster
gcloud container clusters get-credentials ${GKE_CLUSTER_NAME} --region $REGION

# Create the Dataproc on GKE cluster
gcloud dataproc clusters gke create ${DP_CLUSTER_NAME} \
  --project=${PROJECT_ID} \
  --region=${REGION} \
  --gke-cluster=${GKE_CLUSTER_NAME} \
  --spark-engine-version='latest' \
  --staging-bucket=${DPGKE_LOG_BUCKET} \
  --setup-workload-identity \
  --properties "dataproc:dataproc.gke.agent.google-service-account=${UMSA_FQN}" \
  --properties "dataproc:dataproc.gke.spark.driver.google-service-account=${UMSA_FQN}" \
  --properties "dataproc:dataproc.gke.spark.executor.google-service-account=${UMSA_FQN}" \
  --pools="name=${DPGKE_CONTROLLER_POOLNAME},roles=default,machineType=n1-standard-4,min=0,max=3,locations=${ZONE}" \
  --pools="name=${DPGKE_DRIVER_POOLNAME},roles=spark-driver,machineType=n1-standard-4,min=0,max=3,locations=${ZONE}" \
  --pools="name=${DPGKE_EXECUTOR_POOLNAME},roles=spark-executor,machineType=n1-standard-4,min=0,max=3,locations=${ZONE},localSsdCount=1" 
```

Known issues and workarounds:
1. If the node pools dont exist, you may see an error with the creation of the second node pool. <br>
Workaround: 
```
# 1a. Delete namespace
kubectl delete namespace $DPGKE_NAMESPACE

# 1b. Delete Dataproc GKE cluster
gcloud dataproc clusters delete ${DP_CLUSTER_NAME}

# 1c. Rerun the command at section 2.1 - create a Dataproc GKE cluster
```

### 3.2. Review namespaces created

#### 3.2.1. Namespaces

Paste in Cloud Shell-
```
kubectl get namespaces
```

Here is the author's output-
```
----THIS IS INFORMATIONAL---
NAME                                STATUS   AGE
default                             Active   8h
dpgke-cluster-static-420530778089   Active   14m
kube-node-lease                     Active   8h
kube-public                         Active   8h
kube-system                         Active   8h
----INFORMATIONAL----
```
The dpgke* namespace is the Dataproc GKE cluster namespace

#### 3.2.2. Pods

Paste in Cloud Shell-
```
DPGKE_CLUSTER_NAMESPACE=`kubectl get namespaces | grep dpgke | cut -d' ' -f1`
kubectl get pods -n $DPGKE_CLUSTER_NAMESPACE
```
Here is the author's output-
```
----THIS IS INFORMATIONAL---
NAME                                                   READY   STATUS    RESTARTS   AGE
agent-6b6b69458f-4scmr                                 1/1     Running   0          30m
spark-engine-6577d5497f-mftx2                          1/1     Running   0          30m
----INFORMATIONAL----
```


#### 3.2.3. Node pools

After creation of the Dataproc GKE cluster in our lab, there should only be an extra node pool.

Paste in Cloud Shell-
```
kubectl get nodes -L cloud.google.com/gke-nodepool | grep -v GKE-NODEPOOL | awk '{print $6}' | sort | uniq -c | sort -r
```
Here is the author's output-
```
----THIS IS INFORMATIONAL---
      1 dpgke-pool-default
      1 default-pool
----INFORMATIONAL----
```
dpgke-pool-default is the new one created for the Dataproc GKE cluster.


#### 3.2.4. Nodes with node pool name

Paste in Cloud Shell-
```
kubectl get nodes -L cloud.google.com/gke-nodepool
```

Here is the author's output-
```
----THIS IS INFORMATIONAL---
NAME                                                  STATUS   ROLES    AGE     VERSION           GKE-NODEPOOL
gke-dataproc-gke-bas-dpgke-pool-defau-61a73f7d-xw5k   Ready    <none>   30m     v1.25.8-gke.500   dpgke-pool-default
gke-dataproc-gke-base-42-default-pool-aa627942-s50g   Ready    <none>   8h      v1.25.8-gke.500   default-pool
----INFORMATIONAL----
```

<hr>

## 4. Run a Spark job on the cluster

### 4.1. Submit the SparkPi job on the cluster

```
gcloud dataproc jobs submit spark \
  --project=${PROJECT_ID} \
  --region=${REGION} \
  --id="dpgke-sparkpi-$RANDOM" \
  --cluster=${DP_CLUSTER_NAME} \
  --class=org.apache.spark.examples.SparkPi \
  --jars=local:///usr/lib/spark/examples/jars/spark-examples.jar \
  -- 1000
```

Author's output-
```
23/09/06 18:00:13 INFO org.sparkproject.jetty.server.handler.ContextHandler: Started o.s.j.s.ServletContextHandler@1c4ee95c{/,null,AVAILABLE,@Spark}
23/09/06 18:00:13 INFO org.sparkproject.jetty.server.handler.ContextHandler: Started o.s.j.s.ServletContextHandler@5aa360ea{/api,null,AVAILABLE,@Spark}
23/09/06 18:00:13 INFO org.sparkproject.jetty.server.handler.ContextHandler: Started o.s.j.s.ServletContextHandler@35e52059{/jobs/job/kill,null,AVAILABLE,@Spark}
23/09/06 18:00:13 INFO org.sparkproject.jetty.server.handler.ContextHandler: Started o.s.j.s.ServletContextHandler@49bd54f7{/stages/stage/kill,null,AVAILABLE,@Spark}
23/09/06 18:00:18 INFO org.sparkproject.jetty.server.handler.ContextHandler: Started o.s.j.s.ServletContextHandler@78054f54{/metrics/json,null,AVAILABLE,@Spark}
23/09/06 18:01:04 WARN org.apache.spark.scheduler.TaskSchedulerImpl: Initial job has not accepted any resources; check your cluster UI to ensure that workers are registered and have sufficient resources
23/09/06 18:01:19 WARN org.apache.spark.scheduler.TaskSchedulerImpl: Initial job has not accepted any resources; check your cluster UI to ensure that workers are registered and have sufficient resources
23/09/06 18:01:34 WARN org.apache.spark.scheduler.TaskSchedulerImpl: Initial job has not accepted any resources; check your cluster UI to ensure that workers are registered and have sufficient resources
Pi is roughly 3.141682791416828
23/09/06 18:01:54 INFO org.sparkproject.jetty.server.AbstractConnector: Stopped Spark@21680803{HTTP/1.1, (http/1.1)}{0.0.0.0:4040}
23/09/06 18:01:54 WARN org.apache.spark.scheduler.cluster.k8s.ExecutorPodsWatchSnapshotSource: Kubernetes client has been closed (this is expected if the application is shutting down.)
```

### 4.2. Node pools as the job runs

Paste in Cloud Shell-
```
kubectl get nodes -L cloud.google.com/gke-nodepool | grep -v GKE-NODEPOOL | awk '{print $6}' | sort | uniq -c | sort -r
```
Here is the author's output-
```
----THIS IS INFORMATIONAL---
      1 dpgke-pool-executor
      1 dpgke-pool-driver
      1 dpgke-pool-default
      1 default-pool
----INFORMATIONAL----
```

### 4.3. Nodes as the job runs
Paste in Cloud Shell-
```
kubectl get nodes -L cloud.google.com/gke-nodepool
```

Here is the author's output-
```
----THIS IS INFORMATIONAL---
NAME                                                  STATUS   ROLES    AGE     VERSION           GKE-NODEPOOL
gke-dataproc-gke-bas-dpgke-pool-defau-61a73f7d-xw5k   Ready    <none>   30m     v1.25.8-gke.500   dpgke-pool-default
gke-dataproc-gke-bas-dpgke-pool-drive-2d585a56-flgf   Ready    <none>   2m44s   v1.25.8-gke.500   dpgke-pool-driver
gke-dataproc-gke-bas-dpgke-pool-execu-ae26574b-fs2l   Ready    <none>   26s     v1.25.8-gke.500   dpgke-pool-executor
gke-dataproc-gke-base-42-default-pool-aa627942-s50g   Ready    <none>   8h      v1.25.8-gke.500   default-pool
----INFORMATIONAL----
```

Note that the executor and drive node pools show up

### 4.4. Pods

Paste in Cloud Shell-
```
DPGKE_CLUSTER_NAMESPACE=`kubectl get namespaces | grep dpgke | cut -d' ' -f1`
kubectl get pods -n $DPGKE_CLUSTER_NAMESPACE
```

Here is the author's output-
```
----THIS IS INFORMATIONAL---
# While running
NAME                                                   READY   STATUS    RESTARTS   AGE
agent-6b6b69458f-4scmr                                 1/1     Running   0          42m
dp-spark-c56d7f4c-18ae-3c96-9690-0ec23b44d3f0-driver   2/2     Running   0          2m20s
dp-spark-c56d7f4c-18ae-3c96-9690-0ec23b44d3f0-exec-1   0/1     Pending   0          15s
dp-spark-c56d7f4c-18ae-3c96-9690-0ec23b44d3f0-exec-2   0/1     Pending   0          15s
spark-engine-6577d5497f-mftx2                          1/1     Running   0          42m
-------------------------------------------------------------------------------------------
# After completion
NAME                                                   READY   STATUS      RESTARTS   AGE
agent-6b6b69458f-4scmr                                 1/1     Running     0          31m
dp-spark-79821ac2-26f5-3218-90fd-88f84cdc666e-driver   0/2     Completed   0          4m3s
spark-engine-6577d5497f-mftx2                          1/1     Running     0          31m
-------------------------------------------------------------------------------------------
# After several minutes of idle time
NAME                                                   READY   STATUS      RESTARTS   AGE
agent-6b6b69458f-4scmr                                 1/1     Running     0          31m
spark-engine-6577d5497f-mftx2                          1/1     Running     0          31m
-------------------------------------------------------------------------------------------
```

### 4.5. Driver logs in GKE

```
DRIVER=`kubectl get pods -n $DPGKE_CLUSTER_NAMESPACE | grep driver | cut -d' ' -f1`
kubectl logs $DRIVER -n $DPGKE_CLUSTER_NAMESPACE -f
```

Author's output:
```
Defaulted container "driver" out of: driver, logging-sidecar, init (init)
PYSPARK_PYTHON=/opt/conda/bin/python
JAVA_HOME=/usr/lib/jvm/temurin-8-jdk-amd64
SPARK_EXTRA_CLASSPATH=
Merging Spark configs
Skipping merging /opt/spark/conf/spark-defaults.conf, file does not exist.
Skipping merging /opt/spark/conf/log4j.properties, file does not exist.
Skipping merging /opt/spark/conf/spark-env.sh, file does not exist.
Skipping custom init script, file does not exist.
Running heartbeat loop
23/09/06 18:10:05 INFO org.sparkproject.jetty.util.log: Logging initialized @6081ms to org.sparkproject.jetty.util.log.Slf4jLog
23/09/06 18:10:05 INFO org.sparkproject.jetty.server.Server: jetty-9.4.40.v20210413; built: 2021-04-13T20:42:42.668Z; git: b881a572662e1943a14ae12e7e1207989f218b74; jvm 1.8.0_322-b06
23/09/06 18:10:06 INFO org.sparkproject.jetty.server.Server: Started @6383ms
23/09/06 18:10:06 INFO org.sparkproject.jetty.server.AbstractConnector: Started ServerConnector@21680803{HTTP/1.1, (http/1.1)}{0.0.0.0:4040}
23/09/06 18:10:06 INFO org.sparkproject.jetty.server.handler.ContextHandler: Started o.s.j.s.ServletContextHandler@74d7184a{/jobs,null,AVAILABLE,@Spark}
23/09/06 18:10:06 INFO org.sparkproject.jetty.server.handler.ContextHandler: Started o.s.j.s.ServletContextHandler@22ee2d0{/jobs/json,null,AVAILABLE,@Spark}
23/09/06 18:10:06 INFO org.sparkproject.jetty.server.handler.ContextHandler: Started o.s.j.s.ServletContextHandler@3e792ce3{/jobs/job,null,AVAILABLE,@Spark}
23/09/06 18:10:06 INFO org.sparkproject.jetty.server.handler.ContextHandler: Started o.s.j.s.ServletContextHandler@4b770e40{/jobs/job/json,null,AVAILABLE,@Spark}
23/09/06 18:10:06 INFO org.sparkproject.jetty.server.handler.ContextHandler: Started o.s.j.s.ServletContextHandler@54a3ab8f{/stages,null,AVAILABLE,@Spark}
23/09/06 18:10:06 INFO org.sparkproject.jetty.server.handler.ContextHandler: Started o.s.j.s.ServletContextHandler@6a1ebcff{/stages/json,null,AVAILABLE,@Spark}
23/09/06 18:10:06 INFO org.sparkproject.jetty.server.handler.ContextHandler: Started o.s.j.s.ServletContextHandler@50b0bc4c{/stages/stage,null,AVAILABLE,@Spark}
23/09/06 18:10:06 INFO org.sparkproject.jetty.server.handler.ContextHandler: Started o.s.j.s.ServletContextHandler@6b739528{/stages/stage/json,null,AVAILABLE,@Spark}
23/09/06 18:10:06 INFO org.sparkproject.jetty.server.handler.ContextHandler: Started o.s.j.s.ServletContextHandler@41de5768{/stages/pool,null,AVAILABLE,@Spark}
23/09/06 18:10:06 INFO org.sparkproject.jetty.server.handler.ContextHandler: Started o.s.j.s.ServletContextHandler@28fa700e{/stages/pool/json,null,AVAILABLE,@Spark}
23/09/06 18:10:06 INFO org.sparkproject.jetty.server.handler.ContextHandler: Started o.s.j.s.ServletContextHandler@e041f0c{/storage,null,AVAILABLE,@Spark}
23/09/06 18:10:06 INFO org.sparkproject.jetty.server.handler.ContextHandler: Started o.s.j.s.ServletContextHandler@11963225{/storage/json,null,AVAILABLE,@Spark}
23/09/06 18:10:06 INFO org.sparkproject.jetty.server.handler.ContextHandler: Started o.s.j.s.ServletContextHandler@11ee02f8{/storage/rdd,null,AVAILABLE,@Spark}
23/09/06 18:10:06 INFO org.sparkproject.jetty.server.handler.ContextHandler: Started o.s.j.s.ServletContextHandler@61a5b4ae{/storage/rdd/json,null,AVAILABLE,@Spark}
23/09/06 18:10:06 INFO org.sparkproject.jetty.server.handler.ContextHandler: Started o.s.j.s.ServletContextHandler@5b69fd74{/environment,null,AVAILABLE,@Spark}
23/09/06 18:10:06 INFO org.sparkproject.jetty.server.handler.ContextHandler: Started o.s.j.s.ServletContextHandler@437e951d{/environment/json,null,AVAILABLE,@Spark}
23/09/06 18:10:06 INFO org.sparkproject.jetty.server.handler.ContextHandler: Started o.s.j.s.ServletContextHandler@63a5e46c{/executors,null,AVAILABLE,@Spark}
23/09/06 18:10:06 INFO org.sparkproject.jetty.server.handler.ContextHandler: Started o.s.j.s.ServletContextHandler@49ef32e0{/executors/json,null,AVAILABLE,@Spark}
23/09/06 18:10:06 INFO org.sparkproject.jetty.server.handler.ContextHandler: Started o.s.j.s.ServletContextHandler@6bd51ed8{/executors/threadDump,null,AVAILABLE,@Spark}
23/09/06 18:10:06 INFO org.sparkproject.jetty.server.handler.ContextHandler: Started o.s.j.s.ServletContextHandler@51abf713{/executors/threadDump/json,null,AVAILABLE,@Spark}
23/09/06 18:10:06 INFO org.sparkproject.jetty.server.handler.ContextHandler: Started o.s.j.s.ServletContextHandler@4d4d48a6{/static,null,AVAILABLE,@Spark}
23/09/06 18:10:06 INFO org.sparkproject.jetty.server.handler.ContextHandler: Started o.s.j.s.ServletContextHandler@1c4ee95c{/,null,AVAILABLE,@Spark}
23/09/06 18:10:06 INFO org.sparkproject.jetty.server.handler.ContextHandler: Started o.s.j.s.ServletContextHandler@5aa360ea{/api,null,AVAILABLE,@Spark}
23/09/06 18:10:06 INFO org.sparkproject.jetty.server.handler.ContextHandler: Started o.s.j.s.ServletContextHandler@35e52059{/jobs/job/kill,null,AVAILABLE,@Spark}
23/09/06 18:10:06 INFO org.sparkproject.jetty.server.handler.ContextHandler: Started o.s.j.s.ServletContextHandler@49bd54f7{/stages/stage/kill,null,AVAILABLE,@Spark}
23/09/06 18:10:10 INFO org.sparkproject.jetty.server.handler.ContextHandler: Started o.s.j.s.ServletContextHandler@78054f54{/metrics/json,null,AVAILABLE,@Spark}
23/09/06 18:10:55 WARN org.apache.spark.scheduler.TaskSchedulerImpl: Initial job has not accepted any resources; check your cluster UI to ensure that workers are registered and have sufficient resources
23/09/06 18:11:10 WARN org.apache.spark.scheduler.TaskSchedulerImpl: Initial job has not accepted any resources; check your cluster UI to ensure that workers are registered and have sufficient resources
Pi is roughly 3.1414571514145715
23/09/06 18:11:38 INFO org.sparkproject.jetty.server.AbstractConnector: Stopped Spark@21680803{HTTP/1.1, (http/1.1)}{0.0.0.0:4040}
23/09/06 18:11:38 WARN org.apache.spark.scheduler.cluster.k8s.ExecutorPodsWatchSnapshotSource: Kubernetes client has been closed (this is expected if the application is shutting down.)
```

### 4.6. Executor logs in GKE

Similar to the above. Identify the executor of your choice and run the ```kubectl logs``` command.

<hr>

## 5. BYO Peristent History Server & Dataproc Metastore Service

In Lab 2, we created a Persistent History Server and a Dataproc Metastore. To use the two, we just need to reference it during Dataproc cluster creation.

```
----THIS IS INFORMATIONAL---
PERSISTENT_HISTORY_SERVER_NAME="dpgce-sphs-$PROJECT_NBR"

gcloud dataproc clusters gke create ${DP_CLUSTER_NAME} \
  --project=${PROJECT_ID} \
  --region=${REGION} \
  --gke-cluster=${GKE_CLUSTER_NAME} \
  --properties="spark:spark.sql.catalogImplementation=hive,spark:spark.hive.metastore.uris=thrift://<METASTORE_HOST>:<PORT>,spark:spark.hive.metastore.warehouse.dir=<WAREHOUSE_DIR>"
  --spark-engine-version='latest' \
  --staging-bucket=${DPGKE_LOG_BUCKET} \
  --setup-workload-identity \
  --properties "dataproc:dataproc.gke.agent.google-service-account=${UMSA_FQN}" \
  --properties "dataproc:dataproc.gke.spark.driver.google-service-account=${UMSA_FQN}" \
  --properties "dataproc:dataproc.gke.spark.executor.google-service-account=${UMSA_FQN}" \
  --pools="name=${DPGKE_CONTROLLER_POOLNAME},roles=default,machineType=n1-standard-4,min=0,max=3,locations=${ZONE}" \
  --pools="name=${DPGKE_DRIVER_POOLNAME},roles=spark-driver,machineType=n1-standard-4,min=0,max=3,locations=${ZONE}" \
  --pools="name=${DPGKE_EXECUTOR_POOLNAME},roles=spark-executor,machineType=n1-standard-4,min=0,max=3,locations=${ZONE},localSsdCount=1" \
  --history-server-cluster=${PERSISTENT_HISTORY_SERVER_NAME} \
----THIS IS INFORMATIONAL---
```

To use a Persistent History Server (Spark UI), include the line -
```
--history-server-cluster=${PERSISTENT_HISTORY_SERVER_NAME} \
```
And for Dataproc Metastore/Hive Metastore-
```
--properties="spark:spark.sql.catalogImplementation=hive,spark:spark.hive.metastore.uris=thrift://<METASTORE_HOST>:<PORT>,spark:spark.hive.metastore.warehouse.dir=<WAREHOUSE_DIR>"
```

<hr>

## 6. Custom images

Documentation is below; Lab module to be added in the near future.
https://cloud.google.com/dataproc/docs/guides/dpgke/dataproc-gke-custom-images

<hr>

## 7. Spark UI
Is the Persistent Histroy Server covered in the section 4.

## 8. Logging

When a job is executing, go to the Dataproc cluster UI, click on the Dataproc on GKE cluster, and then and click on the job running. Click on "View logs". You will see the following filters-
```
----THIS IS INFORMATIONAL AND IS THE AUTHOR'S DETAILS---
resource.type="k8s_container"
resource.labels.cluster_name="dataproc-gke-base-420530778089"
resource.labels.namespace_name="dpgke-cluster-static-420530778089"
resource.labels.container_name="controller"
```

Navigate into the logs and search for drivers, executors by playing with the ```resource.labels.container_name``` filter value (```executor```, ```driver```).
<hr>

This concludes the lab. Dont forget to shut down the project.

<hr>
