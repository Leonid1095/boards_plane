#!/bin/bash
# This is a script used by the devcontainer to build the project

# install dependencies
yarn install

# Build Server Dependencies
yarn plgames @affine/server-native build
yarn plgames @affine/reader build

# Create database
yarn plgames @affine/server prisma migrate reset -f
