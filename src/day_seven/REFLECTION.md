Well I'm a day behind because of prepping for a DnD session, but day 7 was a fun problem that
wasn't overly challenging. My runtime is over a minute and I am certain that if I spent some more
time thinking through my solution I could find a better way to do things.

My solution to today's addition/multiplication/concatenation problem is a recursive algorithm that
checks each line one operator and one set of values at a time. The solution basically goes:

```
Compare first value of inputs against the target value
    If it is greater kill this entire branch
    If it is less continue on with the recursion
    If it is equal *and* we have only have one value in the inputs then this branch is good

For each operator [add, multiply, concatanate]:
    Apply it to the first 2 inputs
    Recursively check the rest of the line with the applied value as the first input

    If the recursive check returns true for this operator, also return true
```

I think one way to optimize this would be to recursively check from the other direction (instead of
left to right on the inputs we go right to left) so that way you aren't recalculating inputs that
you know will ultimately raise the total higher than is acceptable. That said, I really couldn't
wrap my head around how to simply implement this, and since I'm a day behind I'm happy to just move
on with *a* correct solution and start on Day 8.

+ * || 2 stars, onwards to problem 8.

See you in a bit gamers.
