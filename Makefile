
#########################################################################
# Makefile Usage:
#
# 1) Make sure that you have the curl command line executable in your path
# 2) Set the variable ROKU_DEV_TARGET in your environment to the IP
#    address of your Roku box. (e.g. export ROKU_DEV_TARGET=192.168.1.1.
#    Set in your this variable in your shell startup (e.g. .bashrc)
# 3) and set up the ROKU_DEV_PASSWORD environment variable, too
##########################################################################

APPNAME = Jellyfin_Roku
VERSION = 1.6.3

ZIP_EXCLUDE= -x xml/* -x artwork/* -x \*.pkg -x storeassets\* -x keys\* -x \*/.\* -x *.git* -x *.DS* -x *.pkg* -x dist/**\*  -x out/**\* 

include app.mk

dev: 
	$(MAKE) BUILD='dev' package

beta: 
	$(MAKE) BUILD='beta' package

release: 
	$(MAKE) BUILD='release' package

deploy: prep_staging remove install
