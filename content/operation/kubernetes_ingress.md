---
title: Using in your Kubernetes Ingress
weight: 25
disableToc: false
chapter: false
---

You can use different types of _Ingress_ controllers for your kubernetes cluster. Some ingress support out of the box the usage of CRS.

## NGINX Ingress Controller

It is built around the [Kubernetes Ingress resource](https://kubernetes.io/docs/concepts/services-networking/ingress/), using a [ConfigMap](https://kubernetes.io/docs/concepts/configuration/configmap/) to store the controller configuration.

You can learn more about using [Ingress](http://kubernetes.io/docs/user-guide/ingress/) in the official [Kubernetes documentation](https://docs.k8s.io).

### Installing

See [the upstream install guide](https://github.com/kubernetes/ingress-nginx/blob/main/docs/deploy/index.md) for a whirlwind tour that will get you started.

### Configuration

There are plenty of [examples](https://github.com/kubernetes/ingress-nginx/tree/main/docs/examples) on how to configure the controllers.

{{% notice note %}}
All the configuration is done via the configmap. All options for ModSecurity and the CRS can be found in the [annotations list](https://github.com/kubernetes/ingress-nginx/blob/main/docs/user-guide/nginx-configuration/annotations.md#modsecurity).
{{% /notice %}}

The default ModSecurity configuration file is located in `/etc/nginx/modsecurity/modsecurity.conf`. This is the only file located in this directory and contains the default recommended configuration. Using a volume we can replace this file with the desired configuration. To enable the ModSecurity feature we need to specify `enable-modsecurity: "true"` in the configuration configmap.

The directory `/etc/nginx/owasp-modsecurity-crs` contains the CRS repository. Using `enable-owasp-modsecurity-crs: "true"` we enable the use of the rules.

### Problems

{{% notice warning %}}
If you want to get individual rule alerts but they are not visible in the error log (you are only seeing `949110`), you need to set the annotation `error-log-level: warn`
{{% /notice %}}
