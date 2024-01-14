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
2. Enable the following APIs on for you project(s): IAM, Resource Manager, Cloud Run and Secret Manager 
3. A [Artifact Registry Docker Repository](https://cloud.google.com/artifact-registry/docs/repositories/create-repos#create-gcloud)
4. A [GCS Bucket](https://cloud.google.com/storage/docs/creating-buckets) for Tofu state management
5. A Workload Identity Federation identity pool and identity provider, according to Google's instructions on [Enabling Keyless Authentication for Github Actions](https://cloud.google.com/blog/products/identity-security/enabling-keyless-authentication-from-github-actions)
6. Recommended: [gcloud CLI](https://cloud.google.com/sdk/docs/install) to facilitate project setup

## Configuration

After creating a new repository from this template, follow this steps to configure it.

### 1. Setup a Service Account

First setup a these variables. These are example values. Fill in with your actual values.
```bash
PROJECT_ID=my-project-id
WIF_POOL=projects/123456789/locations/global/workloadIdentityPools/my-pool
WIF_SERVICE_ACCOUNT_NAME=devops-svc
GAR_REPOSITORY_NAME=my-gar-repo
GAR_LOCATION=us-central1
TF_STATE_BUCKET=my-tf-bucket-12438709
GH_REPO=altxtech/cloudrun-project-template
```

Create a Service Account
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
	--condition=None

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${WIF_SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/iam.serviceAccountUser" \
	--condition=None

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${WIF_SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/iam.serviceAccountAdmin" \
	--condition=None

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${WIF_SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/resourcemanager.projectIamAdmin" \
	--condition=None

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${WIF_SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/run.admin" \
	--condition=None
	
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${WIF_SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/secretmanager.admin" \
	--condition=None
```

Give the Service Account access to read and write artifacts from the repository:
```bash
gcloud artifacts repositories add-iam-policy-binding $GAR_REPOSITORY_NAME \
    --location=$GAR_LOCATION \
    --member="serviceAccount:${WIF_SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/artifactregistry.repoAdmin" 
```

Give the Service Account access to manage the TF state in the GCS bucket
```bash
gcloud storage buckets add-iam-policy-binding gs://${TF_STATE_BUCKET} \
        --member="serviceAccount:${WIF_SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
        --role=roles/storage.objectUser
```

Give Github Actions Access to impersonate the service account through Workload Identity Federation
```bash
gcloud iam service-accounts add-iam-policy-binding "${WIF_SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --project="${PROJECT_ID}" \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/${WIF_POOL}/attribute.repository/${GH_REPO}"
```

**Recommended**: Specially if you intend to use one GCP project for each environment, setup two different accounts, one for dev and another for prod, in their respective GCP projects

### 2. Configuring Environment Variables

You need to configure
