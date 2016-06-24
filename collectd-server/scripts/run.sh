#!/bin/bash

/etc/init.d/nginx restart

collectd -f
