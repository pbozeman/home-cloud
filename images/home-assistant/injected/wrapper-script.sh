#!/bin/bash

set -e

cp -Lrf /injected/config/* /config

exec /init
