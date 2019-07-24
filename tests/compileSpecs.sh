#!/bin/bash

set -e

npx elm make ./src/Specs/*Spec.elm --output specs.js
