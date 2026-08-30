#!/usr/bin/env bash

# Count running containers
running=$(docker ps -q | wc -l)

if [ "$running" -gt 0 ]; then
    echo "{\"text\": \" $running\", \"class\": \"running\"}"
else
    echo ""
fi

