<!---->
  Copyright 2022 Google LLC
 
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
 
       http://www.apache.org/licenses/LICENSE-2.0
 
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
 <!---->
 
## A. Environment Provisioning

### 1. Clone the repo

Upload the repository to the Google Cloud Shell instance

<hr>

### 2. IAM Roles needed to execute the prereqs
Ensure that you have **Security Admin**, **Project IAM Admin**, **Service Usage Admin**, **Service Account Admin** and **Role Administrator** roles. This is needed for creating the GCP resources and granting access to attendees.

<hr>

### 3. Cloud-shell Provisioning

#### 3.1. Provisioning the lab resources

```
cd ~/table-format-lab-delta/00-scripts-and-config/cloud-shell
```

Edit the value of the following variable from the 'cloud-shell-execution-admin.md' file <br>

```
LOCATION="<YOUR_GCP_REGION_HERE>"
```

#### 3.2 Running the bash script to create the resources 

```
bash cloud-shell-script-admin.sh
 ```
 
### 4. Roles required for the Hackfest Attendees

Please grant the following GCP roles to all attendees to execute the hands-on labs:<br>

```
Artifact Registry Writer
BigQuery Admin
Dataproc Editor
Dataproc Worker
Notebooks Admin
Notebooks Runner
Service Account User
Storage Admin
Vertex AI administrator
```
