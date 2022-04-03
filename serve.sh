#!/bin/bash

rm -rf public.copy && cp -r public public.copy

zola serve
