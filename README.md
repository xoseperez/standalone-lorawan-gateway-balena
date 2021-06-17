# The Things Stack LoRaWAN Network Server with Balena

![TTS LNS with Balena for Raspberry Pi](https://raw.githubusercontent.com/xoseperez/balena-tts-lns/master/resources/logo_small.png)

This project deploys the The Things Stack LoRaWAN Network Server (Open Source Edition) with balena. It runs on a Raspberry Pi (3/4) or balenaFin.

This is a Work In Progress. It should work just fine for local (LAN) deployments, still needs a lot of testing for other environments.

## Requirements

### Hardware

* Raspberry Pi 3/4 or [balenaFin](https://www.balena.io/fin/)
* SD card in case of the RPi 3/4
* Power supply and (optionally) ethernet cable

### Software

* A balenaCloud account ([sign up here](https://dashboard.balena-cloud.com/))
* [balenaEtcher](https://balena.io/etcher)

### Network

Right now, the self-signed certificates will only work if you have a domain nme pointing to the device. To do so you will need:

* Configure a static IP for the device (either in the device itself or using a DHCP lease on your router)
* Configure a domain (or a subdomain of a domain you already have) pointing to the device

Check the `Configuring the domain` section below for different options to fulfull these two requirements. Once all of this is ready, you are able to deploy this repository following instructions below.

## Deploy

You have two options here:

### One-click deploy via [Balena Deploy](https://www.balena.io/docs/learn/deploy/deploy-with-balena-button/)

Running this project is as simple as deploying it to a balenaCloud application. You can do it in just one click by using the button below:

[![](https://www.balena.io/deploy.png)](https://dashboard.balena-cloud.com/deploy?repoUrl=https://github.com/xoseperez/balena-tts-lns)

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
git clone https://github.com/xoseperez/balena-tts-lns.git
cd balena-tts-lns
git submodule update --init
```
- Enable optional services (see `Adding other services` section below)
- Using [Balena CLI](https://www.balena.io/docs/reference/cli/), push the code with `balena push <application-name>`
- See the magic happening, your device is getting updated 🌟Over-The-Air🌟!

## Boot process

Now a special container in the device will be notified of the new services to download and install. This will take a few minutes and the services will reboot 2 or 3 times until configuration is complete. In the meantime you can configure the `TTS_DOMAIN` variable in the `Device variables` section in the Balena dashboard. A complete list of variables can be found be `Variables` section below, but this one is required. Set the `TTS_DOMAIN` variable to the domain you configured. The `stack` service won't boot if this variables is not defined.

## Log in

Point your browser to the domain name you have defined before using HTTPS and use the default credentials (admin/changeme) to log in as administrator.

Besides configuring the platform to your needs, if you are using a concentrator with a BasicStation services this is the time to create a gateway with the EUI de `basicstation` service provices in the logs and create a key for it.

## Details

### Insight on the start up tasks 

The initial script performs a series of tasks, prior to boot the service. These tasks are:

* Build a configuration file based on environment variables
* Create a self signed certificate
* Configure the identity database
  * Initialize it
  * Create an admin
  * Create oauth clients for the CLI and the console
* Pupulate the TC_URI and TC_TRUST variables for other services to use

Certificates are recreated if TTS_DOMAIN or any TTS_SUBJECT_* variable below changes.
Database is reset if TTS_DOMAIN, TTS_ADMIN_EMAIL, TTS_ADMIN_PASSWORD or TTS_CONSOLE_SECRET change.

### Configuring the domain

In order to connect from a gateway service (even in the same device) with a BasicStation protocol you will need a proper domain name to generate the certificates. If you don't care about secure connections then using the LAN IP of the device as TTS_DOMAIN will work just fine. Anyway, **the service won't start until a TTS_DOMAIN is defined** for the device.

#### Static IP

To properly configure a domain or subdomain you will have to configure the Raspberry Pi with a static address. You have two options here:

1. Configure a static lease on your home router linking the RPi MAC with an IP. Everytime the RPi boots it will ask for an IP using DHCP (this is the default) and router will allways gfive it the same IP.

2. Configure a static IP on the RPi itself instead of using DHCP. Check the [Balena OS documentation](https://www.balena.io/docs/reference/OS/network/2.x/#setting-a-static-ip) to know how to do this, but it has to be done once the initial BalenaOS image boots.

#### Domain or subdomain

Once you know the PI will always be accessible at the same IP, there are a number of ways to define a domain name or a subdomain pointing to the device IP. 

1. Using a DNS in your LAN, like PiHole, dnsmask,... these will work great inside your LAN. But this option requires an extra step since BalenaOS by default uses Google DNS servers (8.8.8.8). So you have to instruct it to use your local DNS server instead. You can do that by editing the `/mnt/boot/config.json` file in the Host adding this line (change the IP to match that of your DNS server):

```
"dnsServers": "192.168.1.11"
```

You can also do it using the Balena CLI on the BalenaOS image you downloaded previously. Like this:

```
balena config write --type raspberrypi4-64 --drive <downloaded.img> dnsServers "<dns_server>"
```

Also note that if you are using the static IP aproximation above, the DNSs are configured on the same connection file, change them there.

2. Using a third party service, like Cloudflare, for instance. If you are managing a domain from such a service you can just add an A register for a subdomain pointing to your local (or public) IP address.

```
A lns.ttn.cat 192.168.1.25
```

Then you just have to wait for the domain name to propagate.

### Variables

Variable Name | Value | Description | Default
------------ | ------------- | ------------- | -------------
**TTS_SERVER_NAME** | `STRING` | Name of the server | The Things Stack
**TTS_DOMAIN** | `STRING` | Domain | Empty by default, must be populated so the service can run
**TTS_ADMIN_EMAIL** | `STRING` | Admin email | admin@thethings.example.com
**TTS_NOREPLY_EMAIL** | `STRING` | Email used for communications | noreply@thethings.example.com
**TTS_ADMIN_PASSWORD** | `STRING` | Admin password (change it here or in the admin profile) | changeme
**TTS_CONSOLE_SECRET** | `STRING` | Console secret | console
**TTS_DEVICE_CLAIMING_SECRET** | `STRING` | Device claiming secret | device_claiming
**TTS_METRICS_PASSWORD** | `STRING` | Metrics password | metrics
**TTS_PPROF_PASSWORD** | `STRING` | Profiling password | pprof
**TTS_SMTP_HOST** | `STRING` | SMTP Server |  
**TTS_SMTP_USER** | `STRING` | SMTP User |  
**TTS_SMTP_PASS** | `STRING` | SMTP Password |  
**TTS_SENDGRID_KEY** | `STRING` | Sendgrid API Key (SMTP_HOST has to be empty in order to use this) | 
**TTS_SUBJECT_COUNTRY** | `STRING` | Self Certificate country code| ES
**TTS_SUBJECT_STATE** | `STRING` | Self Certificate state | Catalunya
**TTS_SUBJECT_LOCATION** | `STRING` | Self Certificate city | Barcelona
**TTS_SUBJECT_ORGANIZATION** | `STRING` | Self Certificate organization | TTN Catalunya

### Adding other services

#### Add WiFi Connect

[WiFi Connect](https://github.com/balena-os/wifi-connect) is a utility for dynamically setting the WiFi configuration on a Linux device via a captive portal. WiFi credentials are specified by connecting with a mobile phone or laptop to the access point that WiFi Connect creates.

To add it you your project you just have to:

1. Make sure you have checked out the submodules in the repo with `git module update --init`.
2. Edit the `docker-compose.yml` file and uncomment the WiFi Connect service.

Then you can just push the application as exploined above.

#### Add BasicStation LoRaWAN Gateway Protocol

If you have a device with a LoRaWAN concentrator (any of the RAK Developer Gateways with a Raspberry Pi inside) you can build a self contained LoRaWAN Gateway with Network Server in a few clicks. A GIT submodule is defined using [Balena BasicStation project](https://github.com/balenalabs/basicstation). 

To add it you your project you just have to:

1. Make sure you have checked out the submodules in the repo with `git module update --init`.
2. Edit the `docker-compose.yml` file and uncomment the BasicStation service.

Now you ca do a `balena push <application-name>` (see deploy via Balena CLI above).

Notice the `stack` service will populate the `TC_URI` and `TC_TRUST` variables, but you will still have to create a key for the gateway and add it to the `TC_KEY` variable. See the [Balena BasicStation repository](https://github.com/balenalabs/basicstation) for more help.

## Troubleshooting

* Self certificates are not working unless the device has a domain. Any help here would be much appreciated. Give your Pi a static address and use a DNS to add a domain pointing to it. See the `Configure the domain` section above.

* If the database fails to initialize the best way to force the start script to init it again is to change any of these variables: TTS_DOMAIN, TTS_ADMIN_EMAIL, TTS_ADMIN_PASSWORD or TTS_CONSOLE_SECRET.

* When the database is reconfigured (because you change any of the environment variables in the previous point) the passwords for the admin and the console are overwritten. So if you are logged in as admin you will have to logout and login again with the default password.

## TODO

* Lots of testing :)
* Testing performance (# of devices) on different platforms
* Option to use ACME / Let's Encrypt for valid certificates
* Option to configure a connection to the Packet Broker
* Include UDP packet forwarder (currently only compatible with SX1301 concentrators)

## Attribution

- This is based on the [The Things Network LoRaWAN Stack repository](https://github.com/TheThingsNetwork/lorawan-stack).
- This is in joint effort by [Xose Pérez](https://twitter.com/xoseperez/) and [Marc Pous](https://twitter.com/gy4nt/) from the TTN community in Barcelona.
