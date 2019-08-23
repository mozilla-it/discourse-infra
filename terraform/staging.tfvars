#############
# Discourse #
#############
"discourse-url" = "discourse-staging.itsre-apps.mozit.cloud"

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

