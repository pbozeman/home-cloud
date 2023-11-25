#!/bin/bash

set -e

cp -r /injected/config/* /config

exec /init
