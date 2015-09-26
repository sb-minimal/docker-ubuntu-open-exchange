docker-ubuntu-open-exchange
========================

Minimal Docker Image running OpenExchange

Run it using

```
docker run -d -p 8080:80 sbminimal/docker-ubuntu-open-exchange
```

and access it via your webbrowser at [http://127.0.0.1:8080/](http://127.0.0.1:8080/).

If you want to persist your data, you can link the /data directory to some "local-directory" using

```
docker run -d -p 8080:80 -v <local-directory>:/data sbminimal/docker-ubuntu-open-exchange
```


