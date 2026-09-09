# VictoriaMetrics stores HertzBeat's collected metrics (the time-series history).
# Reached only over Railway's private network, so it listens on the port Railway
# routes to. The data path is a SUBDIRECTORY of the mount point so the volume
# root's `lost+found` is never treated as part of the storage.
FROM victoriametrics/victoria-metrics:v1.95.1
CMD ["-storageDataPath=/vmdata/data", "-httpListenAddr=:8080", "-retentionPeriod=3"]
