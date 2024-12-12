Day 11, a sneaky little O(N^2) problem! The first part was easily brute forceable, part 2, not so
much. This is my first real experience with a nasty lil O(N^2) in a long while, but it was fun to
run into a problem that wasn't theoretically hard to solve, but was more important to optimize.

My solution ended up being a depth first approach, where I would recursively blink each stone, and
then record its value and the number of blinks remaining as the key, and the number of stones it
ultimately ended up creating as the value in a hash map. Then for the next stone I would check to
see if I'd blinked a stone with the same value at the same depth already using the hash map, and if
I did I'd return that found value instead of continuing to go down the split path.

+2 hashed stars.

SEe you tomorrow gamers.
