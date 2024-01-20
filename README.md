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
2. Enable the required APIs:
4. A [GCS Bucket](https://cloud.google.com/storage/docs/creating-buckets) for Tofu state management
5. Recommended: [gcloud CLI](https://cloud.google.com/sdk/docs/install) to facilitate project setup

## Configuration

After creating a new repository from this template, follow this steps to configure it.

*Note:* This template and configuration guide *assumes both the GAR Repository and GCS Bucket are deployed within the same project as the application stack*. It is not too modify the `deploy.sh` and the configuration steps to enable these possibilites. However, I prefered to assume all resources inthe same project to simplify the configuration process. 

### 1. Setup Workload Identity Federation for Github Actions

You can read more on this on Google Blog's on [Enabling Keyless Authentication from Github Actions](https://cloud.google.com/blog/products/identity-security/enabling-keyless-authentication-from-github-actions)  

On this step, we're going to create service account for Github Actions, and then give GH permissions to impersonate this account with
Workload Identity Federation (WIF).

Create a Service Account
```bash
WIF_SERVICE_NAME=[Name for the account]
gcloud iam service-accounts create $WIF_SERVICE_ACCOUNT_NAME \
    --description="Devops account for Cloud Run projects" \
    --display-name="Devops Service Account for Cloud Run"
```

Create a Wokload Indentity pool
```bash
gcloud iam workload-identity-pools create "ci-cd" \
  --location="global" \
  --display-name="CI/CD"
```

Create a provider
```bash
gcloud iam workload-identity-pools providers create-oidc "github-actions" \
  --location="global" \
  --workload-identity-pool="ci-cd" \
  --display-name="Github Actions" \
  --attribute-mapping="google.subject=assertion.sub,attribute.repository=assertion.repository" \
  --issuer-uri="https://token.actions.githubusercontent.com"
```

You can then, print the workload identity pool name with. We need it for the next step.
```bash
gcloud iam workload-identity-pools describe ci-cd --location global
```

Finally, give Github Actions access to impersonate this account.
```
WIF_POOL=[Resource name of the pool]
PROJECT_ID=[Id of your project]
GH_REPO=[Your repository name, in the format your-org/your-repo] 
gcloud iam service-accounts add-iam-policy-binding "${WIF_SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --project="${PROJECT_ID}" \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/${WIF_POOL}/attribute.repository/${GH_REPO}"
```

### 2. Give the Service Account permissions

Github Actions now has an account it can impersonate, but this account itself has no permissions.

We need to give it permissions to manage the required infrastructure.

Artifact Registry:
```bash
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${WIF_SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/artifactregistry.admin" \
	--condition=None
```

Secret Manager:
```bash
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${WIF_SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/secretmanager.admin" \
	--condition=None

```

Firestore:
```bash
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${WIF_SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/datastore.owner" \
	--condition=None

```

IAM Service Accounts:
```bash
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${WIF_SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/iam.serviceAccountUser" \
	--condition=None

```

```bash
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${WIF_SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/iam.serviceAccountAdmin" \
	--condition=None

```

Resource Manager:
```bash
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${WIF_SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/resourcemanager.projectIamAdmin" \
	--condition=None

```

Cloud Run:
```bash
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${WIF_SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/run.admin" \
	--condition=None
```

And also give the service account access to manage state in the TF Bucket.
```	
TF_BUCKET=[Your TF bucket name]
gcloud storage buckets add-iam-policy-binding gs://${TF_STATE_BUCKET} \
        --member="serviceAccount:${WIF_SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
        --role=roles/storage.objectUser
```


**Recommended**: Do this step twice, one for `dev` and other `prod`. Use different projects, GCS buckets ans service accounts

### 2. Configuring Environment Variables

- **SERVICE**
  - **Name:** `SERVICE`
  - **Description:** Name of the service. Used for naming deployed resources. Recommended to set as a Repository Variable for consistent naming of resources across environments.
  - **Example:** `my-service`

- **ENV**
  - **Name:** `ENV`
  - **Description:** Used for namespacing resources to their specific environment. Also passed as an environment variable to the Cloud Run service.
  - **Example:** `dev`

- **PROJECT_ID**
  - **Name:** `PROJECT_ID`
  - **Description:** Project where the application stack will be deployed. Recommend using a separate project per environment.
  - **Example:** `my-project-dev`

- **REGION**
  - **Name:** `REGION`
  - **Description:** Region where the application stack will be deployed.
  - **Example:** `us-central1`

- **TF_BUCKET**
  - **Name:** `TF_BUCKET`
  - **Description:** Backend configuration for OpenTofu. At least one of these needs to be environment-specific. Recommended to have separate buckets for each environment.
  - **Example:** `my-tf-bucket-dev-213496087`

- **TF_PREFIX**
  - **Name:** `TF_PREFIX`
  - **Description:** Backend configuration for OpenTofu. If storing state for both environments in a single bucket, specify a different prefix or workspace for each environment.
  - **Example:** `my-service-state`

- **TF_WORKSPACE**
  - **Name:** `TF_WORKSPACE`
  - **Description:** Backend configuration for OpenTofu (Optional). If storing state for both environments in a single bucket, specify a different prefix or workspace for each environment.
  - **Example:** `dev-workspace`

- **WIF_PROVIDER**
  - **Name:** `WIF_PROVIDER`
  - **Description:** Workload Identity Federation configuration. Should be in the format `projects/736537866288/locations/global/workloadIdentityPools/ci-cd/providers/github-actions`.
  - **Example:** `projects/0123456789/locations/global/workloadIdentityPools/ci-cd/providers/github-actions`

- **WIF_SERVICE_ACCOUNT**
  - **Name:** `WIF_SERVICE_ACCOUNT`
  - **Description:** Workload Identity Federation configuration. Recommended to have separate configuration for each environment.
  - **Example:** `devops-svc@my-project-dev.iam.gserviceaccount.com`

## Dev and Prod environments

If the Workload Identity Federation and the environment variables are configured correctly, a deployment job will trigger on pushes for the `main` and `dev` branches. Which will respectivelly deploy to the `prod` and `dev` environments.

## Accessing the Secret Manager Secret and Firestore Database from your serviceAccountAdmin

The service will be deployed with the `ENV`, `SECRET_ID` and `DATABASE_ID` environment variables. Use the appropriate Google Cloud client libraries to interact with these resources. 

## Modifying the Secret Value

The secret will be deployed with a default 'secret-data' value. You can modify this value after deploymenth through the GCP console or the gcloud cli. If you instead prefer to set these secret values at deploymeht, you can can modify the deploy.sh file, inthe `Tofu Plan` step, to include a `--var "secret_value=${{ secrets.< your secret name > }}"`, then set said secret as repository or environment secret. 

## Additional Workflows
There are two more additional workflows you might want to use from time to time.

### Force Unlock
This workflow will unlok a TF State lock. If you cancel a deployment job after the environment entered a locked state, it is possible that the environment will
be stuck at said locked state and you won't be able to do any subsequent deployment attempts.  

In that case, get the get the Lock ID from the Deploy job error logs and pass it into the Force Unlock workflow and you will be able to deploy again.

### Destroy
For when you no longer need your app, delete all the cloud resources.
