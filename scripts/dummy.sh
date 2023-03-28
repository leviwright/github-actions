#! /bin/bash

{ # try

    if [ 1 -gt 2 ] &&
    echo "holy crap"

} || { # catch
    echo "Caught you"
}