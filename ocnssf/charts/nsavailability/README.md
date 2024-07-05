opyright 2019 (C), Oracle and/or its affiliates. All rights reserved.

# NSAvailability

## Introduction

This chart runs a pod of nsavailability.

## Installing the Chart

This Chart is subchart under `ocnssf` Umbrella Chart. 
It is present in repository path  cne-repo/nsavailability and 
installed as part of `ocnssf`` Umbrella Chart

## Configuration

The following table lists the configurable parameters of the nsavailability chart and their default values.

| Parameter                              | Description                                  | Default                            |
| ---------------------------------------| -------------------------------------------- | ---------------------------------- |
| `image`                                | `nsavailability` image repository.           | `nsavailability`                   |
| `imageTag`                             | `nsavailability` image tag.                  | `latest`                           |
| `imagePullPolicy`                      | Image pull policy                            | `Always`                           |
