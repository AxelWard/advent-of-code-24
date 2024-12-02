Overall I found the first day to be pretty trivial, which is likely the point. The majority of day
one was spent trying to remember Zig syntax and get comfortable with it again.

The first problem presented an immediate seemingly easy solution. Parse the file into 2 arrays, sort
the arrays, then iterate through them and compare each value and add the difference to my total
difference. I implemented my own "absolute value" check, basically just making sure I never add a
negative value to the total difference. I'm sure there's a more efficient way you could do this with
a custom sort function, but with getting everything setup I was a bit short on time and took my first
solution today.

The second problem requires a bit more of an elegant solution, and I think that the arrays *need* to be
sorted for this solution. The idea is to iterate over the first array, and check the second array as
you go. If you find a value that is less than the value currently in the first array, you do nothing
and continue. If you find a value that is equal to the value currently in the first array, you add one
to the occurrences and continue. If you find a value that is greater than the value currently in the
first array you stop, save that elements index as the next place to start with the next element in the
first array. Then you multiply the number of occurrences by the first elements value, add it to your
similarity value, and continue on with the next element in the array.

I think there is a potential bug in my second implementation, but the particular input I got did not
end up triggering it. Imagine the inputs

```
4   2
4   4
4   5
```

The total similarities *should* be 12 (4 * 1 + 4 * 1 + 4 * 1), my solution will give 4 though. I would
fix this if I had more time, but today ain't that day bucko.

+2 stars, but a guilty second star. Going forward I'll try to think through more potential solutions
and write ideas here in future days, but that's for Axel that isn't tired from Thanksgiving and ready
to get a good Sunday night sleep before a busy work week.

See you tomorrow gamers.
