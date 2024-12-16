Wowee today was a doozee... Not because the problem was inherently hard, but because the
implementation of part 2 was a pretty sweet collision detection problem.

The solution is pretty straightforward: If the character is moving, move the boxes the direction
the character is going to move, as long as there isn't a wall in the way. For part 1 when the boxes
were all the same dimensions and small this was pretty easy. For part 2 we had to move multiple
"peices" of a box at once, and checking the collisions that happened on the Y direction involved
two spaces instead of one.

My implementation went pretty fast, I decided to implement more of a straightforward manual version
of this vs. a sophisticated collision detection/positioning system. It worked well for the examples
but the difficulty came when two pushed boxes would move the same box because of a diamond
structure. My code initially made it such that the twice pushed box would run the movement logic
twice, which was no bueno. After a couple hours of distracted debugging I finally found the issue,
and implemented a quick fix for it.

I'd like to maybe revisit this with a more sophisticated "object" system, and see if things get
easier or harder, but my intuition is that the calculations will get harder but the implementation
will actually get smaller.

+2 colliding stars.

See you tomorrow gamers.
