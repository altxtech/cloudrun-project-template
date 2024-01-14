# Project Template for Cloud Run

Repository template for Google Cloud Run services deployed through OpenTofu (Terraform).
 Privilege permissions preconfigured
- IaC through OpenTofu (Terraform)
- CI/CD trhough Github Actions
- Dev and Prod environments
- Resource namespacing based on environment name


## Prerequisites

1. At least one [GCP Project](https://developers.google.com/workspace/guides/create-project) 
	- Recommended: 2 Projects, one for Dev and another for Prod
2. At least one [Artifact Registry Docker Repository](https://cloud.google.com/artifact-registry/docs/repositories/create-repos#create-gcloud)
3. At least one [GCS Bucket](https://cloud.google.com/storage/docs/creating-buckets) for Tofu state management
4. Recommended: [gcloud CLI](https://cloud.google.com/sdk/docs/install) to facilitate project setup

## Configuration

After creating a new repository from this template, follow this steps to configure it.

### 1. Setup a Service Account

First setup a these variables:
```bash
PROJECT_ID=my-project-id
WIF_SERVICE_ACCOUNT_NAME=devops-svc
GAR_REPOSITORY_NAME=my-gar-repo
GAR_LOCATION=us-central1
```

Create the Service Account
```bash
gcloud iam service-accounts create $WIF_SERVICE_ACCOUNT_NAME \
    --description="Devops account for Cloud Run projects" \
    --display-name="Devops Service Account for Cloud Run"
```

Give the Service Account access to manage infrastructure in the GCP project
```bash
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${WIF_SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/datastore.owner" \
    --role="roles/iam.serviceAccountUser" \
    --role="roles/iam.serviceAccountAdmin" \
    --role="roles/resourcemanager.projectIamAdmin" \
    --role="roles/run.admin" \
    --role="roles/secretmanager.admin" 
```

Give the Service Account access to read and write artifacts from the repository:
```bash
gcloud artifacts repositories add-iam-policy-binding $GAR_REPOSITORY_NAME \
    --location=$GAR_LOCATION \
    --member="serviceAccount:${WIF_SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/artifactregistry.repoAdmin" 
```


### 1. Setup Indentity Federation for Github Actions

Follow Google's instructions on [Enabling Keyless Authentication for Github Actions](https://cloud.google.com/blog/products/identity-security/enabling-keyless-authentication-from-github-actions), starting from the *Setting up Identity Federation for Github Actions* sections.  

Optionally, you can create two separate Workload Identity Federation providers and Service Accounts, one for dev and another for prod.  

Make sure the service accounts will have proper access to push artifacts to the Artifact Registry repositories, manage .state files in the state TF buckets and to manage infrastructure in the GCP projects where the environments  

### 2. Configure
