---
title: Configuring Logback
linkTitle: 2. Configure Logback
weight: 2
---

The Spring PetClinic application can be configured to use several different Java logging libraries. In this scenario, the application is using `logback`.  To make sure we get the OpenTelemetry information in the logs we need to update a file named `logback.xml` with the log structure and add an OpenTelemetry dependency to the `pom.xml` of each of the services in the PetClinic microservices folders.

First, let's set the Log Structure/Format. SpringBoot will allow you to set a global template, but for ease of use, we will replace the existing content of the `logback-spring.xml` files of each service with the following XML content using a prepared script.

{{% notice note %}}
The following entries will be added:

- `trace_id`
- `span_id`
- `trace_flags`
- `service.name`
- `deployment.environment`
{{% /notice %}}

These fields allow the **Splunk Observability Cloud** to display **Related Content** when used in a pattern shown below:

``` xml
  <pattern>
    logback: %d{HH:mm:ss.SSS} [%thread] severity=%-5level %logger{36} - trace_id=%X{trace_id} span_id=%X{span_id} service.name=%property{otel.resource.service.name} trace_flags=%X{trace_flags} - %msg %kvp{DOUBLE}%n
  </pattern>
```

So, let's run the script that will update the files with the log structure in the format above:

{{< tabs >}}
{{% tab title="Update Logback files" %}}

``` bash
. ~/workshop/petclinic/scripts/update_logback.sh
```

{{% /tab %}}
{{% tab title="Replace Output" %}}

```text
Overwritten /home/splunk/spring-petclinic-microservices/spring-petclinic-admin-server/src/main/resources/logback-spring.xml with new XML content.
Overwritten /home/splunk/spring-petclinic-microservices/spring-petclinic-api-gateway/src/main/resources/logback-spring.xml with new XML content.
Overwritten /home/splunk/spring-petclinic-microservices/spring-petclinic-config-server/src/main/resources/logback-spring.xml with new XML content.
Overwritten /home/splunk/spring-petclinic-microservices/spring-petclinic-customers-service/src/main/resources/logback-spring.xml with new XML content.
Overwritten /home/splunk/spring-petclinic-microservices/spring-petclinic-discovery-server/src/main/resources/logback-spring.xml with new XML content.
Overwritten /home/splunk/spring-petclinic-microservices/spring-petclinic-vets-service/src/main/resources/logback-spring.xml with new XML content.
Overwritten /home/splunk/spring-petclinic-microservices/spring-petclinic-visits-service/src/main/resources/logback-spring.xml with new XML content.
Script execution completed.
```

{{% /tab %}}
{{< /tabs >}}

We can verify if the replacement has been successful by examining the spring-logback.xml file from one of the services:

```bash
cat /home/splunk/spring-petclinic-microservices/spring-petclinic-customers-service/src/main/resources/logback-spring.xml
```
