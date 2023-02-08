# Docker Logstash

Simple repo to use and experiment with Logstash, useful for cluster migrations.

![Migration strategy](./images/strategy.jpg)

We'll simplify the infrastructure of this sample project so not configuring any kind of serious security (self-signed SSL cert only). Use these credentials :

- Username : elastic
- Password : changeme

## TL;DR

Pipeline configuration : `./pipelines/pipeline.conf` (configure endpoint inside)

Start ingestion :

```bash
docker-compose up --build logstash --path.config=/usr/share/logstash/pipeline
```

## Setting up demo servers

We will setup two servers to migrate data from Server A to Server B.

![Migration strategy : configuring servers](./images/strategy_servers.jpg)

1. Configure your host's ulimits to be able to handle high I/O

    ```bash
    sudo sysctl -w vm.max_map_count=500000
    ```

2. Generate certificates and start servers

    ```bash
    docker-compose -f create-certs.yml run --rm create_certs
    docker network create docker_logstash_network
    docker-compose -f serverA.docker-compose.yml up -d
    docker-compose -f serverB.docker-compose.yml up -d
    ```

    Wait a bit the time for the cluster to initialize.

    - Cluster A is accessible at `https://localhost:5601`
    - Cluster B is accessible at `https://localhost:5602`

    You should get something similar to the following screenshot in Kibana :

    ![Elasticsearch servers running, visualized in Kibana](./images/cluster_up.png)

3. Add data to Server A

    We'll run the [Rally](https://github.com/elastic/rally) benchmarking tool to inject data in Server A :

    ```bash
    docker run \
        --name benchmark \
        --rm \
        --network docker_logstash_network \
        elastic/rally:latest \
        race --track=metricbeat --pipeline=benchmark-only \
        --include-tasks="index-append" \
        --challenge=append-no-conflicts \
        --client-options=timeout:30,use_ssl:true,verify_certs:false,basic_auth_user:'elastic',basic_auth_password:'changeme' \
        --target-hosts=https://esA1:9200
    ```

    This will create a `metricbeat` index.

## Configure and run Logstash

We will setup two servers to migrate data from Server A to Server B.

![Migration strategy : configuring Logstash](./images/strategy_logstash.jpg)

- Logstash pipeline : `./pipelines/pipeline.conf` (configure endpoint inside)
- Logstash internal conf : `./conf/logstash.yml`

1. Edit `./pipelines/pipeline.conf`

    Default migrated index configured is `metricbeat`

    Detailed configurations can be found [in the official Logstash documentation](https://www.elastic.co/guide/en/logstash/current/plugins-filters-elasticsearch.html#plugins-filters-elasticsearch-options)

2. Build and run the pipeline

    ```bash
    docker-compose build
    docker-compose run logstash --path.config=/usr/share/logstash/pipeline
    ```

## Clean this project

Run the following commands to shutdown containers and remove volumes for this project :

```bash
docker-compose -f serverA.docker-compose.yml down
docker volume rm docker-logstash_esA1
docker-compose -f serverB.docker-compose.yml down
docker volume rm docker-logstash_esB1
docker network rm docker_logstash_network
```
