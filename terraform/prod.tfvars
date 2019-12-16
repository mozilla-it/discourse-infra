#############
# Discourse #
#############
discourse-url      = "discourse.mozilla.org"
discourse-elb      = "a4973975cda0c11e9807a021c7053ca0"
discourse-cdn-zone = "discourse-prod.itsre-apps.mozit.cloud"


#########
# Redis #
#########
redis-instance  = "cache.t2.small"
redis-num-nodes = 1
redis-version   = "5.0.4"


##########
#  PSQL  #
##########
psql-instance          = "db.t3.small"
psql-version           = "10"
psql-storage-allocated = 30
psql-storage-max       = 100

#################
#  Common Tags  #
#################
workspace-tags = {
  deploy-env = "prod"
}

#################
#     Email     #
#################
ses-domain = "discourse.mozilla.org"
