-include .env

.PHONY: all test clean deploy fund help install snapshot format anvil

build:; forge build

test:; forge test