# The Things Stack LoRaWAN Network Server with Balena

![TTS LNS with Balena for Raspberry Pi](https://raw.githubusercontent.com/xoseperez/balena-tts-lns/master/resources/logo_small.png)

This project deploys the The Things Stack LoRaWAN Network Server (Open Source Edition) with balena. It runs on a Raspberry Pi (3/4) or balenaFin.

This is a Work In Progress. It should work just fine for local (LAN) deployments, still needs a lot of testing for other environments.

## Getting started

### Hardware

* Raspberry Pi 3/4 or [balenaFin](https://www.balena.io/fin/)
* SD card in case of the RPi 3/4

### Software

* A balenaCloud account ([sign up here](https://dashboard.balena-cloud.com/))
* [balenaEtcher](https://balena.io/etcher)

Once all of this is ready, you are able to deploy this repository following instructions below.

## Deploy the code

### Via [Balena Deploy](https://www.balena.io/docs/learn/deploy/deploy-with-balena-button/)

Running this project is as simple as deploying it to a balenaCloud application. You can do it in just one click by using the button below:

[![](https://www.balena.io/deploy.png)](https://dashboard.balena-cloud.com/deploy?repoUrl=https://github.com/xoseperez/balena-tts-lns)

Follow instructions, click Add a Device and flash an SD card with that OS image dowloaded from balenaCloud. Enjoy the magic 🌟Over-The-Air🌟!


### Via [Balena-Cli](https://www.balena.io/docs/reference/balena-cli/)

If you are a balena CLI expert, feel free to use balena CLI.

- Sign up on [balena.io](https://dashboard.balena.io/signup)
- Create a new application on balenaCloud.
- Clone this repository to your local workspace.
- Using [Balena CLI](https://www.balena.io/docs/reference/cli/), push the code with `balena push <application-name>`
- See the magic happening, your device is getting updated 🌟Over-The-Air🌟!

## Configure the Platform

### Insight on the start up tasks 

The initial script performs a series of tasks, prior to boot the service. These tasks are:

* Build a configuration file based on environment variables
* Create a self signed certificate
* Configure the identity database
  * Initialize it
  * Create an admin
  * Create oauth clients for the CLI and the console
* Pupulate the TC_URI and TC_TRUST variables for other services to use

Certificates are recreated if DOMAIN or any SUBJECT_* variable below changes.
Database is reset if DOMAIN, ADMIN_EMAIL, ADMIN_PASSWORD or CONSOLE_SECRET change.

### Configuring the DOMAIN

In order to connect from a gateway service (even in the same device) with a BasicStation protocol you will need a proper domain name to generate the certificates. If you don't care about secure connections then using the LAN IP of the device as DOMAIN will work just fine. Anyway, **the service wont start until a DOMAIN is defined** for the device.

There are a number of ways to define a domain name pointing to the device IP. 

1. Defining it in the `/etc/hosts` of the device host (BalenaOS). It will work but only for services in the same machine. Open a terminal to the host and add the line as below (replacing the domain name):

```
echo "127.0.0.1 lns.ttn.cat" >> /etc/hosts
```

2. Using a DNS in your LAN, like PiHole, dnsmask,... these will work great inside your LAN. Actually you should have a PiHole at home already. But this require an extra step since BalenaOS by default uses Google DNS servers (8.8.8.8). So you have to instruct it to use your local DNS server instead. You can do that by editing the `/mnt/boot/config.json` file in the Host adding this line (change the IP to match that of your DNS server):

```
"dnsServers": "192.168.1.11"
```

You can also do it using the Balena CLI on the BalenaOS image you download. Something like this:

```
balena config write --type raspberrypi4-64 --drive <downloaded.img> dnsServers "<dns_server>"
```

3. Using a third party service, like CloudFlare, for instance. If you are managing a domain from such a service you can just add an A register for a subdomain pointing to your local (or public) IP address.

```
A lns.ttn.cat 192.168.1.25
```

Then you just have to wait for the domain name to propagate.

### Log in

Point your browser to the domain name you have defined before using HTTPS and use the default credentials (admin/changeme) to log in as administrator.

### Variables

Variable Name | Value | Description | Default
------------ | ------------- | ------------- | -------------
**SERVER_NAME** | `STRING` | Name of the server | The Things Stack
**DOMAIN** | `STRING` | Domain | Empty by default, must be populated so the service can run
**ADMIN_EMAIL** | `STRING` | Admin email | admin@thethings.example.com
**NOREPLY_EMAIL** | `STRING` | Email used for communications | noreply@thethings.example.com
**ADMIN_PASSWORD** | `STRING` | Admin password (change it here or in the admin profile) | changeme
**CONSOLE_SECRET** | `STRING` | Console secret | console
**DEVICE_CLAIMING_SECRET** | `STRING` | Device claiming secret | device_claiming
**METRICS_PASSWORD** | `STRING` | Metrics password | metrics
**PPROF_PASSWORD** | `STRING` | Profiling password | pprof
**SMTP_HOST** | `STRING` | SMTP Server |  
**SMTP_USER** | `STRING` | SMTP User |  
**SMTP_PASS** | `STRING` | SMTP Password |  
**SENDGRID_KEY** | `STRING` | Sendgrid API Key (SMTP_HOST has to be empty in order to use this) | 
**SUBJECT_COUNTRY** | `STRING` | Self Certificate country code| ES
**SUBJECT_STATE** | `STRING` | Self Certificate state | Catalunya
**SUBJECT_LOCATION** | `STRING` | Self Certificate city | Barcelona
**SUBJECT_ORGANIZATION** | `STRING` | Self Certificate organization | TTN Catalunya

### Add a gateway service with Balena BasicStation

We can merge this project with a BasicStation in the same device. A GIT submodule is defined using Balena BasicStation project. To check them out just run after cloning the repo:

```
git module init
```

Finally uncomment the corresponding section on the `docker-compose.yml` file and do a `balena push <application-name>` (see deploy via Balena CLI above).
Check each project documentation to properly configure them. Notice the `stack` service will populate the `TC_URI` and `TC_TRUST` variables, but you will still have to create a key for the gateway and add it to the `TC_KEY` variable. See the [Balena BasicStation repository](https://github.com/balenalabs/basicstation) for more help.

## Troubleshooting

* Self certificates are not working along with BasicStation unless the device has a domain. Give your Pi a static address and use a DNS to add a domain pointing to it. See the `Configure the DOMAIN` section above.

* If the database fails to initialize the best way to force the start script to init it again is to change any of these variables: DOMAIN, ADMIN_EMAIL, ADMIN_PASSWORD or CONSOLE_SECRET.


## TODO

* Lots of testing :)
* Testing performance on different platforms
* Option to use ACME / Let's Encrypt for valid certificates
* Option to configure a connection to the Packet Broker
* Include UDP packet forwarder (currently only compatible with SX1301 concentrators)

## Attribution

- This is based on the [The Things Network LoRaWAN Stack repository](https://github.com/TheThingsNetwork/lorawan-stack).
- This is in joint effort by [Xose Pérez](https://twitter.com/xoseperez/) and [Marc Pous](https://twitter.com/gy4nt/) from the TTN community in Barcelona.
