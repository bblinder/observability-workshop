---
title: Log Observer
linkTitle: 60. Log Observer
weight: 60
---

## 1. Introduction

Until this point, we have not touched or changed our code, yet we did receive Trace & Profiling/DB Query performance information.
If we want to get more out of our Java application, we can introduce a small change to our application log setup.

This change will configure the Spring PetClinic application to use an Otel-based format to write logs, This will allow the (Auto)-instrumentation to add Otel relevant information into the logs.

The Splunk Log Observer component is used to view the logs and with this information can automatically relate log information with APM Services and Traces. This feature called **Related Content** will also work with Infrastructure.

## 2. Update Logback config for the services

The Spring PetClinic application can be configured to use several different Java logging libraries. In this scenario, the application is using `logback`.  To make sure we get the otel information in the logs we need to update a file named `logback.xml` with the log structure, and add an Otel dependency to the `pom.xml` of each of the services in the petclinic microservices folders.

First lets set the Log Structure/Format:

Spring boot will allow you to set a global template, but for ease of use, we will replace the existing content of the `logback-spring.xml` files of each service with the following XML content using a prepared script:
Note the following entries that will be added:  

- trace_id
- span_id
- trace_flags
- service.name
- deployment.environment
These fields allow the **Splunk** Observability Cloud Suite** to display **Related Content**:
So let's run the script that will update our log structure with the format above:

{{< tabs >}}
{{% tab title="Update Logback files" %}}

``` bash
. ~/workshop/petclinic/scripts/update_logback.sh
```

{{% /tab %}}
{{% tab title="Replace Output" %}}

```text
Overwritten /home/ubuntu/spring-petclinic-microservices/spring-petclinic-admin-server/src/main/resources/logback-spring.xml with new XML content.
Overwritten /home/ubuntu/spring-petclinic-microservices/spring-petclinic-api-gateway/src/main/resources/logback-spring.xml with new XML content.
Overwritten /home/ubuntu/spring-petclinic-microservices/spring-petclinic-config-server/src/main/resources/logback-spring.xml with new XML content.
Overwritten /home/ubuntu/spring-petclinic-microservices/spring-petclinic-customers-service/src/main/resources/logback-spring.xml with new XML content.
Overwritten /home/ubuntu/spring-petclinic-microservices/spring-petclinic-discovery-server/src/main/resources/logback-spring.xml with new XML content.
Overwritten /home/ubuntu/spring-petclinic-microservices/spring-petclinic-vets-service/src/main/resources/logback-spring.xml with new XML content.
Overwritten /home/ubuntu/spring-petclinic-microservices/spring-petclinic-visits-service/src/main/resources/logback-spring.xml with new XML content.
Script execution completed.
```

{{% /tab %}}
{{< /tabs >}}

We can verify if the replacement has been successful by examining the spring-logback.xml file from one of the services

```bash
cat /home/ubuntu/spring-petclinic-microservices/spring-petclinic-customers-service/src/main/resources/logback-spring.xml
```

## 3. Reconfigure and build the services locally

Before we can build the new services with the updated log format we need to add the dependency to the `Pom.xml`:

```bash
. ~/workshop/petclinic/scripts/add_otel.sh
```

The Services are now ready to be build, so run the script that will use the `maven` command to compile/build/package the PetClinic microservices (Note the -P buildDocker, this will build the new containers):
{{< tabs >}}
{{% tab title="Running maven" %}}

```bash
./mvnw clean install -D skipTests -P buildDocker
```

{{% /tab %}}
{{% tab title="Maven Output" %}}

```text

Successfully tagged quay.io/phagen/spring-petclinic-api-gateway:latest
[INFO] Built quay.io/phagen/spring-petclinic-api-gateway
[INFO] ------------------------------------------------------------------------
[INFO] Reactor Summary:
[INFO] 
[INFO] spring-petclinic-microservices 0.0.1 ............... SUCCESS [  0.770 s]
[INFO] spring-petclinic-admin-server ...................... SUCCESS [01:03 min]
[INFO] spring-petclinic-customers-service ................. SUCCESS [ 29.031 s]
[INFO] spring-petclinic-vets-service ...................... SUCCESS [ 22.145 s]
[INFO] spring-petclinic-visits-service .................... SUCCESS [ 20.451 s]
[INFO] spring-petclinic-config-server ..................... SUCCESS [ 12.260 s]
[INFO] spring-petclinic-discovery-server .................. SUCCESS [ 14.174 s]
[INFO] spring-petclinic-api-gateway 0.0.1 ................. SUCCESS [ 29.832 s]
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time: 03:14 min
[INFO] Finished at: 2024-01-02T12:43:20Z
[INFO] ------------------------------------------------------------------------
```

{{% /tab %}}
{{< /tabs >}}

Given that Kubernetes needs to pull these freshly build images from somewhere, we are going to store them in the repository we set up earlier. To do this, run the script that will push the newly build containers into our local repository:

{{< tabs >}}
{{% tab title="pushing Containers" %}}

```bash
. ~/workshop/petclinic/scripts/push_docker.sh 
```

{{% /tab %}}
{{% tab title="Docker Push Output (partial)" %}}

```text
The push refers to repository [localhost:5000/spring-petclinic-vets-service]
0391386bcb2a: Preparing 
bbb67f51a186: Preparing 
105351d0ada3: Preparing 
49cfeae6cb9f: Preparing 
b4da5101fcde: Preparing 
49cfeae6cb9f: Pushed 
e742c14be110: Mounted from spring-petclinic-visits-service 
540aa741fede: Mounted from spring-petclinic-visits-service 
a1dfe59d4939: Mounted from spring-petclinic-visits-service 
1e99e92c46bf: Mounted from spring-petclinic-visits-service 
f5aa38537736: Mounted from spring-petclinic-visits-service 
d2210512edb4: Mounted from spring-petclinic-visits-service 
8e87ff28f1b5: Mounted from spring-petclinic-visits-service 
local: digest: sha256:42337b2a4ff7d0ac9b7c2cf3c70aa20b7b52d092f1e05d351e031dd7fad956fc size: 3040
The push refers to repository [localhost:5000/spring-petclinic-customers-service]
15d54d9adca8: Preparing 
886f6def5b35: Preparing 
1575ae90e858: Preparing 
ccc884d92d18: Preparing 
b4da5101fcde: Preparing 
ccc884d92d18: Pushed 
e742c14be110: Mounted from spring-petclinic-vets-service 
540aa741fede: Mounted from spring-petclinic-vets-service 
a1dfe59d4939: Mounted from spring-petclinic-vets-service 
1e99e92c46bf: Mounted from spring-petclinic-vets-service 
f5aa38537736: Mounted from spring-petclinic-vets-service 
d2210512edb4: Mounted from spring-petclinic-vets-service 
8e87ff28f1b5: Mounted from spring-petclinic-vets-service 
local: digest: sha256:3601c6e7f58224001946058fb0400483fbb8f1b0ea8a6dbaf403c62b4c1908be size: 3042
```

{{% /tab %}}
{{< /tabs >}}

The containers should now be stored in the local repository, lets confirm by checking the catalog,

```bash
 curl -X GET http://localhost:5000/v2/_catalog 
```

The result should be :

```text
{"repositories":["spring-petclinic-admin-server","spring-petclinic-api-gateway","spring-petclinic-config-server","spring-petclinic-customers-service","spring-petclinic-discovery-server","spring-petclinic-vets-service","spring-petclinic-visits-service"]}
```

## 5. Deploy new services to kubernetes

To see the changes in effect, we need to redeploy the services,  First let change the location of the images from the external repo  to the local one by running the following script:

```bash
. ~/workshop/petclinic/scripts/set_local.sh
```

The result is a new file on disk called **petclinic-local.yaml**
Let switch to the local version by applying the local version of the deployment yaml. First delete the old deplyment with:

```bash
kubectl delete -f ~/workshop/petclinic/petclinic-local.yaml
```

followed by:

```bash
kubectl apply -f ~/workshop/petclinic/petclinic-local.yaml
```

This will cause the containers to be replaced with the local version, you can verify this by checking the containers:

```bash
kubectl describe pods api-gateway |grep Image:
```

The resulting output should say ( again if you see double, its the old container being terminated, give it a few seconds):

```text
  Image:         ghcr.io/signalfx/splunk-otel-java/splunk-otel-java:v1.30.0
  Image:         localhost:5000/spring-petclinic-api-gateway:local
```

## 6. View Logs

First give the service time to get back into sync and lets tail the load generator log again
{{< tabs >}}
{{% tab title="Tail Log" %}}

``` bash
. ~/workshop/petclinic/scripts/tail_logs.sh
```

{{% /tab %}}
{{% tab title="Tail Log Output" %}}

```text
{"severity":"info","msg":"Welcome Text = "Welcome to Petclinic"}
{"severity":"info","msg":"@ALL}"
{"severity":"info","msg":"@owner details page"}
{"severity":"info","msg":"@pet details page"}
{"severity":"info","msg":"@add pet page"}
{"severity":"info","msg":"@veterinarians page"}
{"severity":"info","msg":"cookies was"}
```

{{% /tab %}}
{{< /tabs >}}

From the left-hand menu click on **Log Observer** and ensure **Index** is set to **splunk4rookies-workshop**.

Next, click **Add Filter** search for the field `service_name` select the value `<INSTANCE>-petclinic-service` and click `=` (include). You should now see only the log messages from your PetClinic application.

![Log Observer](../images/log-observer.png)

## 7. Summary

This is the end of the workshop and we have certainly covered a lot of ground. At this point, you should have metrics, traces (APM & RUM), logs, database query performance and code profiling being reported into Splunk Observability Cloud.

**Congratulations!**
<!--
docker system prune -a --volumes

  81  . ~/workshop/petclinic/scripts/add_otel.sh
   82  . ~/workshop/petclinic/scripts/update_logback.sh
   83  ./mvnw clean install -DskipTests -P buildDocker
   84  . ~/workshop/petclinic/scripts/push_docker.sh
   85  . ~/workshop/petclinic/scripts/set_local.sh
   86  kubectl apply -f ~/workshop/petclinic/petclinic-local.yaml
   87  k9s
   88  kubectl delete -f ~/workshop/petclinic/petclinic-local.yaml
   89  kubectl apply -f ~/workshop/petclinic/petclinic-local.yaml
   90  k9s
   91  kubectl delete -f ~/workshop/petclinic/petclinic-local.yaml
   92  kubectl apply -f ~/workshop/petclinic/petclinic-local.yaml
   93  k9s
   94  kubectl get deployments -l app.kubernetes.io/part-of=spring-petclinic -o name | xargs -I % kubectl patch % -p "{\"spec\": {\"template\":{\"metadata\":{\"annotations\":{\"instrumentation.opentelemetry.io/inject-java\":\"true\"}}}}}"
-->