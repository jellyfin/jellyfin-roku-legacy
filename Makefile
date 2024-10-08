##########################################################################
# Need curl and npm in your $PATH
# If you want to get_images, you'll also need convert from ImageMagick
##########################################################################

VERSION := 2.1.8

## usage

.PHONY: help
help:
	@echo "targets"
	@echo "  build-dev    build development package"
	@echo "  build-prod   build production package"
	@echo "  build-tests  build tests package"
	@echo "  format       format brighscripts"
	@echo "  lint         lint code and documentation"
	@echo "  get_images   update official jellyfin images"
	@echo "targets needing ROKU_DEV_TARGET"
	@echo "  home         press the home button on device"
	@echo "  launch       launch installed"
	@echo "targets needing ROKU_DEV_TARGET and ROKU_DEV_PASSWORD"
	@echo "  install      install on device"
	@echo "  remove       remove installed from device"
	@echo "  screenshot   take a screenshot"
	@echo "  deploy       lint, remove, install"
	@echo "environment"
	@echo "  ROKU_DEV_TARGET with device's IP"
	@echo "  ROKU_DEV_PASSWORD with device's password"

## development

BUILT_PKG := out/$(notdir $(CURDIR)).zip

node_modules/: package-lock.json; npm ci

.PHONY: build-dev build-prod build-tests
.NOTPARALLEL: build-dev build-prod build-tests # output to the same file
build-dev: node_modules/; npm run build
build-prod: node_modules/; npm run build-prod
build-tests: node_modules/; npm run build-tests

# default to build-dev if file doesn't exist
$(BUILT_PKG):; $(MAKE) build-dev

.PHONY: format
format: node_modules/; npm run format

.PHONY: lint
lint: node_modules/; npm run lint

## roku box

CURL_CMD ?= curl --show-error

ifdef ROKU_DEV_TARGET

.PHONY: home launch
home:
	$(CURL_CMD) -XPOST http://$(ROKU_DEV_TARGET):8060/keypress/home
	sleep 2 # wait for device reaction
launch:
	$(CURL_CMD) -XPOST http://$(ROKU_DEV_TARGET):8060/launch/dev

ifdef ROKU_DEV_PASSWORD

CURL_LOGGED_CMD := $(CURL_CMD) --user rokudev:$(ROKU_DEV_PASSWORD) --digest

EXTRACT_ERROR_CMD := grep "<font color" | sed "s/<font color=\"red\">//" | sed "s[</font>[["
.PHONY: install remove
install: $(BUILT_PKG) home
	$(CURL_LOGGED_CMD) -F "mysubmit=Install" -F "archive=@$<" -F "passwd=" http://$(ROKU_DEV_TARGET)/plugin_install | $(EXTRACT_ERROR_CMD)
	$(MAKE) launch
remove:
	$(CURL_LOGGED_CMD) -F "mysubmit=Delete" -F "archive=" -F "passwd=" http://$(ROKU_DEV_TARGET)/plugin_install | $(EXTRACT_ERROR_CMD)

.PHONY: screenshot
screenshot:
	$(CURL_LOGGED_CMD) -F mysubmit=Screenshot "http://$(ROKU_DEV_TARGET)/plugin_inspect"
	$(CURL_LOGGED_CMD) -o screenshot.jpg "http://$(ROKU_DEV_TARGET)/pkgs/dev.jpg"

.PHONY: deploy
.NOTPARALLEL: deploy
deploy: lint remove install

endif # ROKU_DEV_PASSWORD

endif # ROKU_DEV_TARGET

## sync branding

CONVERT_CMD ?= convert -gravity center
CONVERT_BLUEBG_CMD := $(CONVERT_CMD) -background "\#000b25"
BANNER := images/banner-dark.svg
ICON := images/icon-transparent.svg

images/:; mkdir $@

.PHONY: redo # force rerun
$(BANNER) $(ICON): images/ redo
	$(CURL_CMD) https://raw.githubusercontent.com/jellyfin/jellyfin-ux/master/branding/SVG/$(@F) > $@

images/logo.png: $(BANNER); $(CONVERT_CMD) -background none -scale 1000x48 -extent 180x48 $< $@
images/channel-poster_fhd.png: $(BANNER); $(CONVERT_BLUEBG_CMD) -scale 535x400 -extent 540x405 $< $@
images/channel-poster_hd.png: $(BANNER); $(CONVERT_BLUEBG_CMD) -scale 275x205 -extent 336x210 $< $@
images/channel-poster_sd.png: $(BANNER); $(CONVERT_BLUEBG_CMD) -scale 182x135 -extent 246x140 $< $@
images/splash-screen_fhd.jpg: $(BANNER); $(CONVERT_BLUEBG_CMD) -scale 540x540 -extent 1920x1080 $< $@
images/splash-screen_hd.jpg: $(BANNER); $(CONVERT_BLUEBG_CMD) -scale 360x360 -extent 1280x720 $< $@
images/splash-screen_sd.jpg: $(BANNER); $(CONVERT_BLUEBG_CMD) -scale 240x240 -extent 720x480 $< $@

.PHONY: get_images
get_images: $(ICON)
get_images: images/logo.png
get_images: images/channel-poster_fhd.png images/channel-poster_hd.png images/channel-poster_sd.png
get_images: images/splash-screen_fhd.jpg images/splash-screen_hd.jpg images/splash-screen_sd.jpg
