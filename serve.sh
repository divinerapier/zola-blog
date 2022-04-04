#!/bin/bash

if [ -f public ]; then
    rm -rf public.copy && cp -r public public.copy
fi

zola serve
