#!/bin/bash

rm -rf public.copy && cp -r public public.copy

zola build && \
    echo "blog.kiyoko.io" > public/CNAME

cp -r public.copy/.git public/

rm -rf public.copy
