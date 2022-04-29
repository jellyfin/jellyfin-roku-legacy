## Developing The Jellyfin Roku App
Follow the steps below to install the app on your personal Roku device for development. 

### Developer Mode

Put your Roku device in [developer mode](https://blog.roku.com/developer/2016/02/04/developer-setup-guide). Write down your Roku device IP and the password you created, you will need these later.

### Clone the GitHub Repo

Navigate to where you'd like to install the app then copy the application files:

```bash
git clone https://github.com/jellyfin/jellyfin-roku.git
```

Open up the new folder:

```bash
cd jellyfin-roku
```

### Install Necessary Packages

```bash
sudo apt-get install wget make zip
```

## Method 1: Sideload to Roku Device Manually

```bash
make dev
```

This will create a zip in `out/apps/Jellyfin_Roku-dev.zip`. Login to your roku's device in your browser and upload the zip file then run install.

## Method 2: Direct load to Roku Device

### Login Details

Run this command - replacing the IP and password with your Roku device IP and dev password from the first step:

```bash
export ROKU_DEV_TARGET=192.168.1.234
export ROKU_DEV_PASSWORD=password
```

Normally you would have to open up your browser and upload a .zip file containing the app code. These commands enable the app to be zipped up and installed on the Roku automatically which is essential for developers and makes it easy to upgrade in the future for users.

### Deploy

Package up the application, send it to your Roku, and launch the channel:

```bash
make install
```

Note: You only have to run this command once if you are not a developer. The Jellyfin channel will still be installed after rebooting your Roku device.

## Bug/Crash Reports

Did the app crash? Find a nasty bug? Use the this command to view the error log and [report it to the developers](https://github.com/jellyfin/jellyfin-roku/issues):

```bash
telnet ${ROKU_DEV_TARGET} 8085
```

To exit telnet: `CTRL + ]` and then type `quit + ENTER`

## Upgrade

Navigate to the folder where you installed the app then upgrade the code to the latest version:

```bash
git pull
```

Deploy the app:

```bash
make install
```

## Developer Setup

Read below and also checkout the [Development Guide For New Devs](DEVGUIDE.md)

### Workflow

Modify code -> `make install` -> Use Roku remote to test changes -> `telnet ${ROKU_DEV_TARGET} 8085` -> `CTRL + ]` -> `quit + ENTER`

Unfortunately there is no debuger. You will need to use telnet to see log statements, warnings, and error reports. You won't always need to telnet into your device but the workflow above is typical when you are new to Brightscript or are working on tricky code.

### Testing

Testing is done with the [Rooibos](https://github.com/georgejecook/rooibos/) library. This works by including tests in the deployment and then looking at telnet
for the test results.

Install necessary packages:

```bash
sudo apt-get install nodejs npm
```

Install [rooibos-cli](https://github.com/georgejecook/rooibos-cli):

```bash
npm install -g rooibos-cli
```

Deploy the application with tests:

```bash
make test
```

View test results:

```bash
telnet ${ROKU_DEV_TARGET} 8085
```

To exit telnet: `CTRL + ]` and then type `quit + ENTER`

### Committing

Before commiting your code, please run:

```bash
make prep_commit
```

This will format your code and run the CI checks locally to ensure you will pass the CI tests.

### (Optional) Update Images

This repo already contains all necessary images for the app. This script only needs to be run when the [official Jellyfin images](https://github.com/jellyfin/jellyfin-ux) are changed to allow us to update the repo images.

Install necessary packages:

```bash
sudo apt-get install imagemagick
```

Download and convert images:

```bash
make get_images
```
