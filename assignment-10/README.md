# Google Deployment Manager

Made for CDS DS 561: Cloud Computing  
Professor: [Leonidas Kontothanassis](https://www.bu.edu/cds-faculty/profile/kthanasi/)

---

An example of using Google Deployment Manager to replicate two of the previous homeworks: homework 2 and homework 5. This assignment consists of two components: a bucket containing the code for the web server, subscriber client, and the mini-web generator and a GDM deployment config which covers the creation of service accounts, Pub/Sub topics and subscriptions, CloudSQL instances and databases, IAM permissions, firewall rules, GCE IPs, and GCE VMs.

## Sections

- [Setup](#setup)
- [Screenshots](#screenshots)
  - [Requests](#requests)
  - [Created Resources](#created-resources)
  - [Deleted Resources](#deleted-resources)

## Setup

### Prerequisites

This assignment assumes you have completed homeworks 2 and 5 and have the files available for upload to a manually created bucket. If not, see the [README](../assignment-2/README.md) for homework 2 and the [README](../assignment-5/README.md) for homework 5.

### Steps

1. Create a bucket for your code
   ```bash
   gsutil mb gs://<code-bucket-name>
   ```
1. Upload the `web-server` and `sub-client` directories to the bucket
   ```bash
   gsutil cp -r web-server gs://<code-bucket-name>
   gsutil cp -r sub-client gs://<code-bucket-name>
   ```
1. Update `deployment.yml` to reflect your project's information.

   - Replace all instances of `ds561-amahr` with your project ID.
   - Update `iam-policy-binding-main-bucket`'s bucket property to reflect your code bucket's name.

1. Run `gcloud deployment-manager deployments create <deployment-name> --config deployment.yml` to create all of the resources.

1. (When finished) Delete the mini web bucket (due to it not being empty) and the deployment.
   ```bash
   gsutil -m rm -r gs://<code-bucket-name>
   gcloud deployment-manager deployments delete <deployment-name>
   ```

## Screenshots

### Requests

![](./assets/part2.png)

cURL 200 response:

![](./assets/part3-200.png)

cURL 404 response:

![](./assets/part3-404.png)

cURL 501 response:

![](./assets/part3-501.png)

`requests` table contents:

![](./assets/part4-all.png)

`failed_requests` table contents:

![](./assets/part4-failed.png)

Pub/Sub listener:

![](./assets/part4-sub.png)

### Created Resources

Created service account:

![](./assets/part6-sa.png)

Created Bucket:

![](./assets/part6-bucket.png)

Created SQL instance:

![](./assets/part6-sql-instance.png)

Created SQL database:

![](./assets/part6-sql-db.png)

Created Pub/Sub topic:

![](./assets/part6-topic.png)

Created Pub/Sub subscription:

![](./assets/part6-sub.png)

Created IAM permissions:

![](./assets/part6-iam.png)

Created firewall rule:

![](./assets/part6-firewall.png)

Created GCE IP:

![](./assets/part6-ip.png)

Created GCE VMs:

![](./assets/part6-vm.png)

### Deleted Resources

Deleted Service Account:

![](./assets/part7-sa.png)

Deleted Bucket:

![](./assets/part7-bucket.png)

Deleted SQL instance:

![](./assets/part7-sql.png)

Deleted Pub/Sub topic:

![](./assets/part7-topic.png)

Deleted Pub/Sub subscription:

![](./assets/part7-sub.png)

Deleted Firewall rule:

![](./assets/part7-firewall.png)

Deleted GCE IP:

![](./assets/part7-ip.png)

Deleted GCE VMs:

![](./assets/part7-vm.png)
