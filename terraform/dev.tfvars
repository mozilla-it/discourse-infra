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
"psql-version" = "11"
"psql-storage-allocated" = 50
"psql-storage-max"  = 100

#################
#  Common Tags  #
#################
"workspace-tags" = {
  "deploy-env" = "dev"
}
