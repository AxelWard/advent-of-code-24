Day 12 was an interesting logical and implementation problem. My solution for part one was pretty
straightforward, but it turns out there aren't a lot of featurs that I'm used to from Scala that
help deal with many optionals (for comprehension, match statements, etc.), so I ended up with very
verbose code.

With part 2 and the extra logic for dealing with calculating the edges that would be added (which
required checking 2 more cells each time you add a cell) I realized I had to come up with a
different approach. For part 2 I implemented some helper functions to deal with the possible null
(out of bounds) cells and then things got a lot easier to keep straight in my head. Once I did this
my solution came together very quickly.

The solution ended up being a lot simpler than I originally thought it would be. For part one its
just a matter of seeing if you need to add perimeter based on the cells above and below the cell
you are trying to add to a plot. For part 2 there is just an extra check on the cells up and to the
right/left to see how the different edges are affected. There aren't really that many cases to
possibly handle, so this O(N) solution is very very nice.

+2 stars, a day late and a helper function short.

See you tomorrow gamers.
