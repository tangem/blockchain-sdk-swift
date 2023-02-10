#!/bin/sh

find . -name 'Localizable.strings' -not -path './Pods/*' -exec sort {} -o {} \;
