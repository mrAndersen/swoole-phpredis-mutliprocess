#!/bin/bash

docker rm -f t_redis1 && \
  docker rm -f t_redis2 && \
  docker rm -f t_redis3 && \
  docker-compose up -d && \
  docker exec -it t_redis1 redis-cli --cluster create redis:6379 redis1:6380 redis2:6381