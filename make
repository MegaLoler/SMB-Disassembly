#!/bin/env sh
asm6f -n mario.asm mario.nes && diff mario.nes mario.nes.original
