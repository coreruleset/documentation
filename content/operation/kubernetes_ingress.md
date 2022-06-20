---
title: Kubernetes Ingress Controllers
weight: 30
disableToc: false
chapter: false
---

> A Kubernetes cluster can use different types of _ingress controllers_ to expose Kubernetes services outside the cluster. Some ingress controllers include built-in support for using CRS, as this page outlines.

## NGINX Ingress Controller

The [NGINX Ingress Controller](https://github.com/kubernetes/ingress-nginx) is built around the [Kubernetes Ingress resource](https://kubernetes.io/docs/concepts/services-networking/ingress/). It uses a [ConfigMap](https://kubernetes.io/docs/concepts/configuration/configmap/) to store the controller configuration.

Refer to the [official Kubernetes documentation](https://docs.k8s.io) to learn more about using the [Ingress resource](https://kubernetes.io/docs/concepts/services-networking/ingress/). 

### Installing

Refer to the [upstream installation guide](https://github.com/kubernetes/ingress-nginx/blob/main/docs/deploy/index.md) for a whirlwind tour to get started.

### Configuration

The upstream project provides [many examples](https://github.com/kubernetes/ingress-nginx/tree/main/docs/examples) of how to configure the controller. These are a good starting point.

{{% notice info %}}
All of the configuration is done via the ConfigMap. All options for ModSecurity and CRS can be found in the [annotations list](https://github.com/kubernetes/ingress-nginx/blob/main/docs/user-guide/nginx-configuration/annotations.md#modsecurity).
{{% /notice %}}

The default ModSecurity configuration file is located at `/etc/nginx/modsecurity/modsecurity.conf`. This is the only file located in this directory and it contains the default recommended configuration. Using a volume, this file can be replaced with the desired configuration. To enable the ModSecurity feature, specify `enable-modsecurity: "true"` in the configuration ConfigMap.

The directory `/etc/nginx/owasp-modsecurity-crs` contains the CRS repository. Use `enable-owasp-modsecurity-crs: "true"` to enable use of the CRS rules.

### Common Problems

{{% notice tip %}}
To get *individual rule alerts*, if they're not visible in the error log (for example, if only log entries for rule `949110` are present in the log file), make sure to set the annotation `error-log-level: warn`.
{{% /notice %}}
