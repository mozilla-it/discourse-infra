#############
# Discourse #
#############
"discourse-url" = "discourse-prod.itsre-apps.mozit.cloud"
"discourse-elb" = "a4973975cda0c11e9807a021c7053ca0"


#########
# Redis #
#########
"redis-instance" = "cache.t2.medium"
"redis-num-nodes" = 1
"redis-version" = "5.0.4"


##########
#  PSQL  #
##########
"psql-instance" = "db.m5.medium"
"psql-version" = "10"
"psql-storage-allocated" = 30
"psql-storage-max"  = 100

#################
#  Common Tags  #
#################
"workspace-tags" = {
  "deploy-env" = "prod"
}

#################
#     Email     #
#################
"ses-domain" = "discourse.mozilla.org"
#"ses-domain" = "discourse-prod.itsre-apps.mozit.cloud"
  
