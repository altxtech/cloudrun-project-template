# Project Template for Cloud Run

## Objectives  
- Deployed with IaC (terraform)
- App container gets built, pushed to ACR and a new revision of the app is deployed
- Support for multiple environments (dev, prod, staging, temp, etc...)


## How to configure the repository

1. Create an artifact registry repository. Can be done via the GCP console, or via the command line:
```
gcloud artifacts repositories create --repository-format docker --location <location> <repo name>
```

1. For each environment (dev and prod) configure the following 5 environment variables
- ENV - Name of the environment. Will be used to namespace resources.
- GAR_LOCATION - The location of the Artifact Registry repository
- PROJECT_ID - ID of the GCP project
- REGION - Region where the app will be deployed to (eg. us-central1)
- SERVICE - A name for your app


Update readme
