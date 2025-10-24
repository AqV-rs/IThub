FROM redis:8.2.1
RUN mkdir -p /etc/redis
COPY redis.conf /etc/redis/redis.conf
VOLUME /data
CMD ["redis-server"]
EXPOSE 6379
