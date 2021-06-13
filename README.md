# The Things Stack LoRaWAN Network Server with Balena

This project deploys the The Things Stack LoRaWAN Network Server (Open Source Edition) with balena. It runs on a Raspberry Pi (3/4) or balenaFin.

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

### Insight on the initial tasks 

The initial script performs a series of tasks, prior to boot the service. These tasks are:

* Build a configuration file based on environment variables
* Create a self signed certificate
* Configure the identity database
  * Initialize it
  * Create an admin
  * Create oauth clients for the CLI and the console

Certificates are recreated if any SUBJECT_* variable below changes.
Database is reset if DOMAIN, ADMIN_EMAIL, ADMIN_PASSWORD or CONSOLE_SECRET change.

#### Variables

Variable Name | Value | Description | Default
------------ | ------------- | ------------- | -------------
**SERVER_NAME** | `STRING` | Name of the server | The Things Stack
**DOMAIN** | `STRING` | Domain | Defaults to the LAN Ip of the devices
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


## Attribution

- This is based on the [The Things Network LoRaWAN Stack repository](https://github.com/TheThingsNetwork/lorawan-stack).
- This is in joint effort by [Xose Pérez](https://twitter.com/xoseperez/) and [Marc Pous](https://twitter.com/gy4nt/) from the TTN community in Barcelona.
