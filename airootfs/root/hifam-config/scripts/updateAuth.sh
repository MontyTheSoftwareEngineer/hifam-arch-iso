#!/usr/bin/env bash

read -rp "Software version: " version
read -rp "Freezer serial: " fsn

fsn=$(printf '%s' "$fsn" | tr '[:lower:]' '[:upper:]')

password="${version}${fsn}1234567890abcdef"

printf '%s' "$password" | sha256sum | cut -c1-6
