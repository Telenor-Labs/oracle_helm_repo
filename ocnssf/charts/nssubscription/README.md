# Copyright 2019 (C), Oracle and/or its affiliates. All rights reserved.

# NsSubscription

## Introduction

This chart runs a pod of nssubscription.

## Installing the Chart

This Chart is subchart under `ocnssf` Umbrella Chart. 
It is present in repository path  cne-repo/nssubscription and 
installed as part of `ocnssf`` Umbrella Chart

## Configuration

The following table lists the configurable parameters of the nssubscription chart and their default values.

| Parameter                              | Description                                  | Default                            |
| ---------------------------------------| -------------------------------------------- | ---------------------------------- |
| `image`                                | `nssubscription` image repository.           | `nssubscription`                   |
| `imageTag`                             | `nssubscription` image tag.                  | `latest`                           |
| `imagePullPolicy`                      | Image pull policy                            | `Always`                           |








