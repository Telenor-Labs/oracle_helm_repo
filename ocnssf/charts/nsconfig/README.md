# Copyright 2019 (C), Oracle and/or its affiliates. All rights reserved.

## Introduction

This chart runs a pod of nsconfig.

## Installing the Chart

This Chart is subchart under `ocnssf` Umbrella Chart. 
It is present in repository path  cne-repo/nsconfig and 
installed as part of `ocnssf`` Umbrella Chart

## Configuration

The following table lists the configurable parameters of the nsconfig chart and their default values.

| Parameter                              | Description                                  | Default                            |
| ---------------------------------------| -------------------------------------------- | ---------------------------------- |
| `image`                                | `nsconfig` image repository.                 | `nsconfig`                         |
| `imageTag`                             | `nsconfig` image tag.                        | `latest`                           |
| `imagePullPolicy`                      | Image pull policy                            | `Always`                           |








