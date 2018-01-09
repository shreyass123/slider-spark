# slider-spark
Docker image and utility scripts to launch a dockerized spark cluster through apache slider on a HDP 2.6 yarn cluster. The docker container has R installed and can run sparkR.

## Prerequisites to run in yarn cluster mode with slider
- /user/slider exists on HDFS and is writable by the user running the slider job
- run.sh script which would issue spark submit (slider/example folder has a sample)
- HDP 2.6 cluster with docker installed on the datanodes (modify the bootstrap.sh script for a different hadoop distribution/version)
- apache slider installed

## Usage in local mode
```
Launch container using:
docker run -d -e CORES=4 -e MEM=4096 -p 8080:8080 shreyass123/slider-spark
```

## Usage in cluster mode
```
slider/launch.sh <app-name> <folder containing run.sh and spark app dependencies>
Ex:
slider/launch.sh sparkr example
slider/destroy.sh <app-name>
```