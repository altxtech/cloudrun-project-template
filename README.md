# Project Template for Cloud Run

## Objectives  
- Deployed with IaC (terraform)
- App container gets built, pushed to ACR and a new revision of the app is deployed
- Support for multiple environments (dev, prod, staging, temp, etc...)


## How to configure the repository

1. Create an artifact registry repository. Can be done via the GCP console, or via the command line:
```
gcloud artifacts repositories create < repository-name > \
--location < region > \
--repository-format docker
```


2. For each environment (dev and prod) configure the following 5 environment variables
- ENV - Name of the environment. Will be used to namespace resources.
- GAR_LOCATION - The location of the Artifact Registry repository
- PROJECT_ID - ID of the GCP project
- REGION - Region where the app will be deployed to (eg. us-central1)
- SERVICE - A name for your app

3. Create a Workload Indentity Provider and a service account in your GCP account.

4. Set the WIF_PROVIDER and WIF_SERVICE_ACCOUNT repository secrets.

5. Create a bucket to store your tofu configurations. Clone the repository and edit the main.tf terraform configuration to set the proper bucket for management:

```
terraform {
  backend "gcs" {
    bucket = "<your backend bucket name>
    prefix = "<the prefix for your configurations>"
  }
}
```

Setting a prefix is specially useful if you intend to store configurations for multiple projects in a single bucket.
