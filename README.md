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

* [The Things Stack](https://github.com/xoseperez/the-things-stack-docker)
* [Basics™ Station](https://github.com/xoseperez/basicstation)
* [Node-RED](https://github.com/balenablocks/balena-node-red)
* [InfluxDB](https://hub.docker.com/_/influxdb)
* [Grafana](https://github.com/balenablocks/dashboard)
* [WiFi-Connect](https://github.com/balena-os/wifi-connect)

Check the differents repos for specific configuration options.

## Deploy

You have two options here:

### One-click deploy via [Balena Deploy](https://www.balena.io/docs/learn/deploy/deploy-with-balena-button/)

Running this project is as simple as deploying it to a balenaCloud application. You can do it in just one click by using the button below:

[![](https://www.balena.io/deploy.png)](https://dashboard.balena-cloud.com/deploy?repoUrl=https://github.com/xoseperez/standalone-lorawan-gateway-balena)

Follow instructions, click Add a Device and flash an SD card with that OS image dowloaded from balenaCloud. Enjoy the magic 🌟Over-The-Air🌟!

### In-control deploy via [Balena-Cli](https://www.balena.io/docs/reference/balena-cli/)

If you are a balena CLI expert, feel free to use balena CLI. This option lets you configure in detail some options, like adding new services to your deploy or configure de DNS Server to use.

- Sign up on [balena.io](https://dashboard.balena.io/signup)
- Create a new application on balenaCloud.
- Add a new device and download the image of the BalenaOS it creates.
- This is the moment to configure the DNS server in the BalenaOS if required. See the `Configuring the domain` section  below.
- Burn and SD card (if using a Pi), connect it to the device and boot it up.

While the device boots (it will eventually show up in the Balena dashboard) we will prepare de services:

- Clone this repository to your local workstation. Don't forget to update the submodules.
```
cd ~/workspace
git clone https://github.com/xoseperez/standalone-lorawan-gateway-balena
cd standalone-lorawan-gateway-balena
```
- Enable/disable services by editing the `docker-compose.yml` file
- Using [Balena CLI](https://www.balena.io/docs/reference/cli/), push the code with `balena push <application-name>`
- See the magic happening, your device is getting updated 🌟Over-The-Air🌟!

## Boot process

Now a special container in the device will be notified of the new services to download and install. This will take a few minutes and the services will reboot 2 or 3 times until configuration is complete. 

## Log in

The different services expose different ports, these are the default ports and credentials to access them. Check the documentation for each of them to know how to change them using variables.

|Service|Port|Username|Password|
|:--|---|---|---|
|The Things Stack|443 (https)|admin|changeme|
|Node-RED|1880|balena|balena|
|InfluxDB|8086|||
|Grafana|3000|balena|balena|
