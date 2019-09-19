#############
# Discourse #
#############
"discourse-url" = "discourse-staging.itsre-apps.mozit.cloud"
"discourse-elb" = "ac23bf095c8af11e99ca602ac9836d17"


#########
# Redis #
#########
"redis-instance" = "cache.t2.small"
"redis-num-nodes" = 1
"redis-version" = "5.0.4"


##########
#  PSQL  #
##########
"psql-instance" = "db.t2.micro"
"psql-version" = "10"
"psql-storage-allocated" = 10
"psql-storage-max"  = 50

#################
#  Common Tags  #
#################
"workspace-tags" = {
  "deploy-env" = "staging"
}

#################
#  Cloudfront   #
#################

#################
#     Email     #
#################
"ses-domain" = "discourse-staging.itsre-apps.mozit.cloud"
