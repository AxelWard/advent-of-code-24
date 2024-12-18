Day 17, the day of reverse recursive searches!

Upon looking at the problem it felt pretty clear that the solution would have something related to
fact the program always reduced the a value by 8 before doing a jump. This, combined with the fact
that doing a brute force search on a 8^16 problem space is basically impossible without a GPU, led
me to try a recursive problem space search, where I search 8 inputs for the last instruction, if I
find it I multiply that value by 8, and search the next values for the next instruction from the
end. After continuing to do that (and being careful not to overflow integers, whoda thought) you
can reasonably quickly crack today's problem!

I must admit that I first tried caching previous results with a hash table. To say that quickly ran
my machine out of memory is an understatement, lol

+2 late night solving stars. I'm off to bed.

See you tomorrow gamers.
