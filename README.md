# discourse-infra
This repository contains the infrastructure code for running discourse.mozilla.org

# Table of content

 - 1 [FAQ](#fac)
 - 2 [User Management](#user-management)
 - 3 [Infrastructure: Terraform](#terraform)
 - 4 [Dependencies](#dependencies)
 - 5 [Secrets](#secrets)
 - 6 [CI/CD](#ci-cd)
 - 7 [Metrics, Logs and Alerts](#metrics-logs-alerts)
 - 8 [Upgrades](#upgrades)


# FAQ
This section contains frequently asked questions with a short answer, read the complete README for longer explanation about these topics.

### What is the AWS account where Discourse lives?
Discourse lives in IT-SRE common applications account, and it is deployed into the common application cluster.

### How can I see when the application was deployed for last time?
Login into the AWS it-sre-apps account. Go to Codebuild, choose "discourse-prod". There you can see when the last "Suceeded" deployment occurs.

You can also use the cli if you want but it's tedious and returns UNIX timestamps: `JOBID=$(aws codebuild list-builds-for-project --project-name discourse-prod --output text --max-items 1 | awk '/IDS/  {print $2}') && aws codebuild batch-get-builds --ids $JOBID --query 'builds[0].[buildStatus, endTime]'`

### How can I trigger a deployment of the application?
Run `aws codebuild start-build --project-name discourse-prod` and folow the progress in the AWS Codebuild UI. Other option is to go to the AWS Codebuild, choose the "discourse-prod" project, and click "Start Build".

### How can I get into the Kubernetes cluster?
`aws eks update-kubeconfig --name k8s-apps-prod-us-west-2`. That will get a kubeconfig for you, now you can run kubectl commands.

### Where can I see how the (healthy) status of Discourse?
1. Check if there are alerts in the Slack channel #discourse-alerts
2. Look at the graphs showing traffic, resources usage and saturation [here](https://biff-5adb6e55.influxcloud.net/d/-wHLuuFZz/discourse?orgId=1&var-env=prod).

### How can I restart the application?
Run 'PODS=$(kubectl get po -n=discourse-prod -l=app=discourse | awk '/discourse/ {print $1}') && for p in $PODS; do kubectl delete po -n=discourse-prod $p ; done`. This will delete the current running pods one by one. This means it will be slow but it won't cause any downtime.

If you want a faster approach you can run `kubectl delete po -n=discourse-prod -l=app=discourse`. This will delete all the running pods and spawn new ones, because you are deleting all the pods at once, the application will experience a small downtime.

# User management
This section describes how to create new users (intented for developers) in AWS and how can they connect to the Kubernetes cluster.
In order connect to the cluster, a user must have installed the next dependencies:
 - awscli >= 1.16.154
 - kubectl >= 1.13 

### Creating a user in AWS
AWS users are managed using Terraform. In order to create a new user, one has to edit the file `terraform/users.tf`. Copy the resources used by the user `lmcardle`, change the name of the new user and run `terraform apply` to apply the changes.

Once Terraform finishes, it should have created a set of credentials which will allow the user to visit the AWS Console. These credentials can be obtained running `terraform output password_username`, the output is a base64 blob containing the GPG encoded password. Now, give the credentials to the new user, she can decrypt the password running: `cat terraform_ouput_pw | base64 -d | keybase gpg decrypt`.

#### Enrolling an MFA device
The default user policy enforces a user to setup MFA, until it is enabled the user will not be able to see or interact without any AWS resource.
In order to enable MFA for her account, the new user has to login into the AWS console, go to the IAM secction and follow the steps described in the UI to enroll her MFA device

#### Generate API keys
Now the user can generate a pair of API keys for using the command line interface. Inside the AWS console, go to IAM, select your user, click on "Security Credentials" and generate them.

### Grant access to the Kubernetes cluster
Granting access for a user to the Kubernetes cluster requires having 2 things: an AWS user with permissions to describe the target EKS cluster (this was done in the previous step), and a role inside Kubernetes granting permissions to certain namespaces. This role is already created for discourse developers, granting access to the 3 namespaces containing the different environments.

Now the AWS user has to be mapped to the Kubernetes role. In order to perform the mapping, edit the `aws-auth` configmap and reflect the new mapping: `kubectl edit configmap aws-auth -n=kube-system`.

### Get EKS credentials and test access
The configuration file which instructs kubectl how to connect to the cluster can be hand crafted, of obtained using the AWS cli. Obtaining it via the AWS cli is the easiest option and can be done running: `aws eks update-kubeconfig --name k8s-apps-prod-us-west-2`, this will create a file in `~/.kube/config`.

It should be all set. Test the access running `kubectl get pods -n=discourse-dev`. If you see a list of pods, you are ready to go. 


# Infrastructure: Terraform
All the AWS resources needed to build, deploy and run Discourse are entirely managed with Terraform. In order to make changes to the infrastructure you must be logged into AWS.

### Using terrafom workspaces
This project uses teraform workspaces for managing the different application environments: development, stage and production. You can list the currently available workspaces with `terraform workspace list` and choose one with `terraform workspace select dev`.
Workspaces have a specific variables file named after them, which you have to specify it in order to modify the specific environment. For example:

`terraform plan -var-file="dev.tfvars"`


# Dependencies
This section aims to list the different resources needed to build, deploy and run Discourse.

### Architecture diagram

### Application dependencies
 - Postgres 
 - Redis
 - Email: SES for sending and receiving email
 - AWS Lamdba for posting the weekly TL;DR and for email processing
 - S3 for storing user uploads, incoming email...

### Other AWS resources needed
 - CDN
 - Route53 domains
 - Codebuild jobs
 - ECR
 - S3 buckets containing Lmbda function code, CDN logs...
 - Users
 - IAM roles to make all components work together.

### Code and configuration repositories:
 - [Discourse](https://github.com/discourse/discourse) Upstream Discourse repository containing application code.
 - [Discourse docker](https://github.com/discourse/discourse_docker) Contains the official scripts to build Discourse into a Docker container.
 - [Discourse Mozilla](https://github.com/mozilla/discourse.mozilla.org) Buildspecs, Kubernetes manifests, environments definition and other configs for Mozilla's custom build of Discourse.
 - [Discourse Infra](https://github.com/mozilla-it/discourse-infra) This repo. Terraform code, Kubernetes manifests for infrastructure components and docs used for sysadmins/operators to create and manage Discourse installations.

# Secrets
All the secrets used by Discourse are set as environment variables, and they are backed into the container at build time. This is bad, but until we can't deconstruct the official building process, is the only option. The container is pushed to a private ECR registry.

The process for adding the secrets into the container uses Codebuild, AWS SSM, Terraform and the official Discourse build scripts to get them backed in. When Terraform creates a Codebuild job for deploying in a specific environment, it fetches secrets from SSM and sets them all the as environment variables to the job (you can see them in the Codebuild job definition), during the building process those variables are written in the file `include/env.yaml`, the Discourse builder uses that file to source the variables.

### Secrets generation and location
Most of the secrets are created and known by Terraform: for example the endpoint of the RDS database or the name of an S3 bucket. However there are other few which can't be created by Terraform and remain secure, for example the password to access the database or the OIDC token used for Auth0. In order to **be consistent** these secrets are also managed by Terraform and stored in AWS SSM but need manual interaction during the bootstrap or rotation time.

The strategy used is to create an SSM parameter with a dummy value using Terraform and add it to the Codebuild enviroment as the other secrets/variables. After the first Terraform run, you can go and overwrite the value of an SSM secret with `aws ssm put-value`. The next Terraform run will add the correct value to the Codebuild job. Terraform has an special annotation for these secret instructing it to not override again the value with the default one.

Using this approach we can be sure that looking at the Terraform code, we are able to figure out **all the secrets** used by the application. You can see the value either as a Terraform output in case like the RDS database endpoint, or using `aws ssm get-parameter` in case of others like the Auth0 OIDC token.


# Application build and deploy: CI/CD
The software choosed to build Discourse is AWS Codebuild, and the platform where is currently hosted is Kubernetes. The reason why using Codebuild for the job, is that on buildtime, the official scripts need access to the database in order to perform migrations and other optimizations. Because of this constraint, Codebuild remains the only easy option.

### Build
The build process can happen automatically comitting to the master branch in the Mozilla Discourse repo, or can happen when initiated by the user via the AWS cli or the console. There is one Codebuildjob for building and deploying to each environment.

Each codebuild job uses a shared `buildspec.yml` file with the commands building the application. Once the container is built, it is uploaded to a private ECR repository.

### Deploy into Kubernetes
The Kubernetes resources needed by Discourse can be found together with other configuration in the Mozilla Discourse repo, inside the `k8s` folder. Those manifests are using local Helm templating in order to share one single manifest with all the environments, where the specific details of each environment are stored into a per-environment variables file.

### Authorizing Codebuild to deploy into Kubernetes EKS
In order to allow the user running Codebuild talk and deploy into the Kubernetes cluster, there are 2 pieces of authorization we need to modify. 

The first one is allowing the user to get the details of the cluster, and this is done using IAM roles. The second one is allowing the user to modify certain Kubernetes resources in specific namespaces. This is accomplished creating Users and Roles inside Kubernetes and mapping the ARN of the Codebuild job to a user inside the cluster. This is done modifying the `aws-auth` configmap in the kube-system namespace.

# Metrics, Logs and Alerts
This section describes which metrics are we gathering for Dicourse and where can you see them, where are the Discourse logs, what conditions are we using for alerting and where the alerts are shown.

## Metrics
This project is gathering 3 different kind of metrics: External loadbalancer metrics (these metrics reflect users experience: 500s, latency and amount of traffic), Internal Kubernetes metrics (like number of replicas running or scaling events) and Docker/CAdvisor metrics (these metrics show resources used by the application like CPU and memory).
There are several components needed for exposing and later consuming and sending this metrics. Most of them are done in the Kubernetes cluster level, for example with metrics-server.

All these metrics are displayed in a single Grafana dashboard [here](https://biff-5adb6e55.influxcloud.net/d/-wHLuuFZz/discourse?orgId=1). There you can filter by environment and, with a glance, see how the application is performing and compare it with the historical data

## Logs
The Discourse application logs its messages to files in the local container. Those logs are picked up by a sidecar container running a Syslog forwader which sends them to Papertrail where they are centrally collected. Use Papertrail to search for logs, evertyhing is send there. 

Also the production.log file (which contains the most important information) is tailed -f by a sidecar container. This makes possible to follow the logs of a specific pod using the kubectl logs feature.

## Alerts
There are 3 different sources from where an alert can be fired: New Relic Synthetics (firing alerts for site unavailability), Papertrail (firing alerts based on log information) and Kapacitor (firing alerts based on application behavior). All 3 applications will send the alerts to #discourse-alerts, and New Relic will send unavailability alerts to #it-sre-bot. There are other destinations, like emails to discoruse-admins@mozilla.comm or paging Alberto, but this is not publicily available.


# Upgrades
In order to upgrade Discourse run the Codebuild job which builds and deploys the application. By default this process builds Discourse from the `test-passed` branch which contains the most up to date code which doesn't break existing test. 
It's recommended to first upgrade dev, later stage and test the site manually creating posts and checking that it is behaving as expected.

