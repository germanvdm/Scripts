#!/bin/bash
#mata el proceso que le pasamos como parametro

kill -9 $(ps aux | grep $1 | head -n 1 | awk {'print $2'})

