# Standalone LoRaWAN Gateway

This project deploys the The Things Stack LoRaWAN Network Server (Open Source Edition), Basics™ Station packet forwarder and other services using Docker or Balena.io. It runs on a PC, a Raspberry Pi 3/4, Compute Module 3/4 or balenaFin with SX1301, SX1302 or SX1303 LoRa concentrators (e.g. RAK831, RAK833, RAK2245, RAK2247, RAK2287, RAK5146, Seeed WM1302 and IMST iC880a among others).

This is a Work In Progress. This is **NOT meant for production environments** but it should work just fine for local (LAN) deployments.

## Introduction

Deploy a Standalone LoRaWAN Gateway running the Basics™ Station Semtech Packet Forwarder and The Things Stack LoRaWAN Network Server in a docker container or as a balena.io fleet.

Main features:

* Support for AMD64 (x86_64), ARMv8 and ARMv7 architectures.
* Support for SX1301, SX1302, EX1303 and SX1308 concentrators.
* Timeseries database and dashboard applications included.
* Almost one click deploy and at the same time highly configurable.

Components used:

* [Basics™ Station](https://github.com/xoseperez/basicstation).
* [The Things Stack](https://github.com/xoseperez/the-things-stack-docker)
* [Node-RED](https://github.com/balenablocks/balena-node-red)
* [InfluxDB](https://hub.docker.com/_/influxdb)
* [Grafana](https://github.com/balenablocks/dashboard)
* [WiFi-Connect](https://github.com/balena-os/wifi-connect)

Check the differents repos for specific configuration options.