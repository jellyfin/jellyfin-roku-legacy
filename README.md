<h1 align="center">Jellyfin Roku</h1>
<h2 align="center">Part of the <a href="https://jellyfin.org">Jellyfin Project</a></h2>

[![Logo Banner](https://raw.githubusercontent.com/jellyfin/jellyfin-ux/master/branding/SVG/banner-logo-solid.svg?sanitize=true "Jellyfin")](https://jellyfin.org)

[![Build Status](https://img.shields.io/github/actions/workflow/status/jellyfin/jellyfin-roku/build-dev.yml?logo=github&branch=unstable "Build Status")](https://github.com/jellyfin/jellyfin-roku/actions/workflows/build-dev.yml?query=branch%3Aunstable)
[![Current Release](https://img.shields.io/github/release/jellyfin/jellyfin-roku.svg?logo=github "Current Release")](https://github.com/jellyfin/jellyfin-roku/releases)
[![Translation Status](https://translate.jellyfin.org/widgets/jellyfin/-/jellyfin-roku/svg-badge.svg "Translation Status")](https://translate.jellyfin.org/projects/jellyfin/jellyfin-roku/?utm_source=widget)
[![Forum](https://img.shields.io/badge/forum-MyBB-00A4DC "Check out our forum!")](https://forum.jellyfin.org/f-roku-development)
[![Matrix](https://img.shields.io/matrix/jellyfin:matrix.org.svg?logo=matrix "Chat on Matrix")](https://matrix.to/#/#jellyfin-dev-roku:matrix.org)
[![License](https://img.shields.io/github/license/jellyfin/jellyfin-roku.svg "GPL 2.0 License")](LICENSE)

Jellyfin Roku is the official Jellyfin client for Roku devices. We welcome all contributions and pull requests! If you have a larger feature in mind please [open an issue](https://github.com/jellyfin/jellyfin-roku/issues/new?assignees=&labels=feature&template=feature_request.md&title=) so we can discuss the implementation before you start.

## Install

Download the latest release on the [Roku Channel Store](https://channelstore.roku.com/details/cc5e559d08d9ec87c5f30dcebdeebc12/jellyfin).

## Get Involved

No matter what your interests or skills are you can help make this client better for everyone by simply using the client and giving feedback to the developers when things break. [Create an issue](https://github.com/jellyfin/jellyfin-roku/issues/new/choose) here on GitHub or give us a shout on [Matrix](https://matrix.to/#/#jellyfin-dev-roku:matrix.org).

## Beta Test

To test the latest features before they get released:

1. Put your Roku device in [developer mode](https://blog.roku.com/developer/2016/02/04/developer-setup-guide). Write down your Roku device IP and the password you created - you will need these!
2. Download the [latest build](https://github.com/jellyfin/jellyfin-roku/actions/workflows/build-dev.yml?query=branch%3Aunstable). Select the first item listed then click the link at the bottom of the page i.e. `Jellyfin-Roku-dev-d3352495c579f6adeca085cdbc137ac36e70d558`. This will download a zip file to your computer.
3. Put your Roku's IP from step 1 into a browser i.e. `http://192.168.1.2` and press enter.
4. Log in with credentials from step 1.
5. Upload and install the zip file downloaded in step 2.

> NOTE: The beta app will always be at the bottom of your Roku's channel list and it will *not* automatically update.

## Advanced

For more advanced deployment methods, access to crash logs, or to learn how to setup a developer environment so you can write some code yourself please read the [DEVGUIDE](DEVGUIDE.md).

## Feature Requests

New feature requests are always welcome but before creating an issue please read through the [existing issues](https://github.com/jellyfin/jellyfin-roku/issues?q=is%3Aissue+is%3Aopen+sort%3Aupdated-desc) to see if someone has already raised one for what you're looking for.
