#!/bin/sh

MKTEMPL_DIR=~/c/mktempl
MCP_DIR=~/c/mcp
HASH_DIR=~/c/mcp/hashtable

cp ${MKTEMPL_DIR}/*.c .
cp ${MCP_DIR}/*.c ${MCP_DIR}/*.h .
cp ${HASH_DIR}/Makefile ${HASH_DIR}/*.c ${HASH_DIR}/*.h ./hashtable/
