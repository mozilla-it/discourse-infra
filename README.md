# discourse-infra
This repository contains the infrastructure code for running discourse.mozilla.org

# User management
This section describes how to create new users in AWS and how can they connect to the Kubernetes cluster.
In order connect to the cluster, a user must have installed the next dependencies:
 - awscli >= 1.16.154
 - kubectl >= 1.13 

## Creating a user in AWS
AWS users are managed using Terraform. In order to create a new user, one has to edit the file `terraform/users.tf`. Copy the resources used by the user `lmcardle`, using the name of the new user and `terraform apply the changes`.

Once Terraform finishes, it should have created a set of credentials which will allow the user to visit the AWS Console. These credentials can be obtained running `terraform output password_username`, the output is a base64 blob containing the GPG encoded password. Now, give the credentials to the new user, she can decrypt the password running: `cat terraform_ouput_pw | base64 -d | keybase gpg decrypt`.

### Enrolling an MFA device
The default user policy enforces a user to setup MFA, until it is enabled the user will not be able to see or interact without any AWS resource.
In order to enable MFA for her account, the new user has to login into the AWS console, go to the IAM secction and follow the steps described in the UI to enroll her MFA device

### Generate API keys
Now the user can generate a pair of API keys for using the command line interface. Inside the AWS console, go to IAM, select your user, click on "Security Credentials" and generate them.

## Grant access to the Kubernetes cluster
Granting access for a user to the Kubernetes cluster requires having 2 things: an AWS user with permissions to describe the target EKS cluster (this was done in the previous step), and a role inside Kubernetes granting permissions to certain namespaces. This role is already created for discourse developers, granting access to the 3 namespaces containing the different environments.

Now the AWS user has to be mapped to the Kubernetes role. In order to perform the mapping, edit the 'aws-auth' configmap and reflect the new mapping: `kubectl edit configmap aws-auth -n=kube-system`.

## Get EKS credentials and test access
The configuration file which instructs kubectl how to connect to the cluster can be hand crafted, of obtained using the AWS cli. Obtaining it via the AWS cli is the easiest option and can be done running: `aws eks update-kubeconfig --name k8s-apps-prod-us-west-2`, this will create a file in `~/.kube/config'.

It should be all set. Test the access running `kubectl get pods -n=discourse-dev`. If you see a list of pods, you are ready to go. 
