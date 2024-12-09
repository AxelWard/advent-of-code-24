Oh baby I love file systems, or at least mock ones! Today's problem was challenging to implement,
but ended up having a pretty simple solution.

Part one was pretty trivial, with my solution focusing on traversing the array in place from each
direction and filling empty indexes found on the left with values from the right.

I knew how I wanted to solve part 2 almost immediately, but I got tripped up on the implementation
when I overcomplicated things by tracking a list of 'files to be pushed' in a hash map. Don't worry
too much about the internals of that solution, just know it was silly lol.

The solution that ended up working well for me was creating a variable length array of a copy of
all the file locations (including the empty ones) and then iterate over it backwards. Every time I
encounterd a file I would then iterate over the list from the beginning looking for a spot that it
would fit, and if it fit somewhere earlier than its current location then I'd move it there. If there
was leftover space I would create a new file location immediately after the moved file with the
leftover space marked as available.

+2 intuitive stars.

See you tomorrow gamers
