# SRE Info

## Infra Access
The application lives in the `it-sre-apps-admin` AWS account, and is running in the shared applications cluster. Create a kubernetes configuration running: `aws-vault exec it-sre-apps-admin -- aws eks update-kubeconfig --name k8s-apps-prod-us-west-2`

## Secrets
All secrets used by this application are stored as SSM key-value pairs under the path '/discourse/$env/'. Use the AWS console or cli to browse them

## Source Repos
Infrastructure repo (this repo) [discourse-infra](https://github.com/mozilla-it/discourse-infra)
Mozilla's Discourse custom build: [discourse.mozilla.org](https://github.com/mozilla/discourse.mozilla.org)


## Monitoring
[Grafana Metrics](https://biff-5adb6e55.influxcloud.net/d/-wHLuuFZz/discourse?orgId=1)
[Papertrail logs Logs](https://my.papertrailapp.com/groups/16153952/events)

## Alerts
Alerts are going to #discourse-infra slack channel as well as emailing discourse-admins@mozilla.com
The source for these alerts are Papertrail and Grafana.

## SSL Certificates
All the SSL certificates used by Discourse are issued by AWS ACM.

[SSL Cert Monitoring](https://metrics.mozilla-itsre.mozit.cloud/d/EsrIYzmWz/traffic?orgId=1)

## Cloud Account
AWS account it-sre-apps-admin 903937621340
