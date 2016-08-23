# docker-mysql-uitl

A Docker container for misc. MySQL utilities implemented in Ruby.

## Lock-and-Snap

For a MySQL database containing MyISAM tables, flush and lock the tables, then create a snapshot.

### Build and Run

```
docker build -t snap .
docker run -it --rm --name snap -e "DB_USER=master" -e "DB_PASSWORD=$DB_PASSWORD" -e "DB_HOST=jadu-test-dev.cpkaf0pdggmt.us-east-1.rds.amazonaws.com" -e "DB_RDS_ID=jadu-test-dev" -e "AWS_PROFILE=commercial" -v ~/.aws:/root/.aws snap
```

### Create/Update Gemfile.lock

```
docker run --rm -v "$PWD":/usr/src/app -w /usr/src/app ruby:2.1 bundle install
```
