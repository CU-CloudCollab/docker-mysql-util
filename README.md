# docker-mysql-util

A Docker container for misc. MySQL utilities implemented in Ruby.

(May move to CU-CloudCollab organization in the future.)

## Lock-and-Snap MySQL Tables

This utility creates snapshots of MySQL RDS databases that contain MyISAM tables. MyISAM tables are not fully supported by the automatic snapshotting available to RDS MyQSL databases. However AWS suggests a methodology ensure that snapshots containing MyISAM tables are usable. In short, the methodology is:
1. Stop all activity to MyISAM tables.
2. Lock and flush all MyISAM tables.
3. Manually create a DB snapshot.
4. Unlock the tables once the snapshot is complete.

See https://confluence.cornell.edu/display/CLOUD/MyISAM+Tables+in+MySQL+RDS+Instances for more details.

The [lock-and-snap.rb] script implements steps 2-4 above. It doesn't forcibly stop activity in MyISAM tables. For database with DB_RDS_ID = "mydb", snapshots will have names like `mydb-<year>-<month>-<day>-<hour>-<minute>`

### Arguments

Arguments are supplied to the script using environment variables. When run inside a Docker container, the argument values are supplied using the `-e "[variable]=[value]'` construct in the Docker run command.

#### Required Arguments

* **DB_HOST** - the endpoint (FQDN or IP address) of the RDS database
* **DB_USER** - the username of a MySQL user with privileges allowing it to lock tables in all schemas (databases)
* **DB_PASSWORD** - the password of the MySQL user
* **DB_RDS_ID** - the ID of the RDS instance (e.g. mydb); this value is the same as the "DB Instance" column in the AWS RDS console; also referenced as "database instance ID" in RDS

#### Optional Arguments

These optional arguments populate tags assigned to the snapshot. If the argument isn't present, the corresponding tag is NOT created.

* **CREATOR_TAG** - the value for the AWS tag with key "Creator"; this can be handy to identity who or what created the snapshot. E.g., if run as a Jenkins job, the value of the KJenkins $BUILD_TAG is useful here.
* **APPLICATION_TAG** - the value for the AWS tag with key "Application"; e.g., "jira"
* **ENVIRONMENT_TAG** - the value for the AWS tag with key "Environment"; e.g., "test"

#### AWS Privileges

In addition to the MySQL-related credentials, this script requires AWS privileges allowing creation and description of snapshots as well as describing RDS instances. These can be focused on specific RDS instances and snapshots. E.g., if the target RDS instances are named with prefix "mydb", then the following IAM policy will provide all necessary privileges:

```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Stmt1472066398464",
            "Action": [
                "rds:CreateDBSnapshot",
                "rds:DescribeDBInstances"
            ],
            "Effect": "Allow",
            "Resource": [
                "arn:aws:rds:us-east-1:123456789012:db:mydb*"
            ]
        },
        {
            "Sid": "Stmt1472066398465",
            "Action": [
                "rds:DescribeDBSnapshots"
            ],
            "Effect": "Allow",
            "Resource": [
                "arn:aws:rds:us-east-1:123456789012:snapshot:mydb*",
                "arn:aws:rds:us-east-1:123456789012:snapshot:rds:mydb*"
            ]
        }
    ]
}

```

### Run lock-and-snap.rb from a Container

This Docker run command models running the script in a container on a local workstation. It assumes that AWS CLI/SDK credentials are setup in the ~/.aws directory. Further, it sets the AWS_PROFILE environment to use the "commercial" profile inside the container.

```
docker build -t snap .
docker run -it --rm --name snap \
  -e "DB_USER=master" \
  -e "DB_PASSWORD=$DB_PASSWORD" \
  -e "DB_HOST=jadu-test-dev.cpkaf0pdggmt.us-east-1.rds.amazonaws.com" \
  -e "DB_RDS_ID=jadu-test-dev" \
  -e "CREATOR_TAG=pea1" \
  -e "APPLICATION_TAG=jadu" \
  -e "ENVIRONMENT_TAG=dev/test" \
  -e "AWS_PROFILE=commercial" \
  -v ~/.aws:/root/.aws snap
```

## Developing

### Create/Update Gemfile.lock

If you changed [Gemfile](Gemfile), you will need to regenerate [Gemfile.lock](Gemfile.lock) to be used by the container.

```
docker run --rm -v "$PWD":/usr/src/app -w /usr/src/app ruby:2.1 bundle install
```