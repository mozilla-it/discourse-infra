#############
# Discourse #
#############
"discourse-url" = "discourse-dev.itsre-apps.mozit.cloud"
"discourse-elb" = "ab30fe62db90e11e99aba06db27de6a9"

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
  "deploy-env" = "dev"
}

#################
#     Email     #
#################
"ses-domain" = "discourse-dev.itsre-apps.mozit.cloud"
  
