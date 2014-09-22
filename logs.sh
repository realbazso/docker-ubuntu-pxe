#!/bin/bash

LOGS=$1

tail --pid $$ -n0 -F $LOGS/* &
