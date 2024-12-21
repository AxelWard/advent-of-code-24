Ah, day 18. Like day 16, but way easier. No joke this one took me like an eighth the time that day
16 took me, but they are incredibly similar problems.

I'm not sure if there is a better way to solve the problem, maybe setting up more checks to
determine when to actually check if there is a route from the start to the finish. My solution is
pretty basic, its just a "add the point, run dijkstra's, repeat".

Funnily enough, this program does crash my computer if I just let it run from the 0 index. I'm sure
there is a memory leak somewhere, but I'm too lazy to track it down now. I guess something I'll
have to look into at some point is either a custom allocator and/or what debugging tools are
available for Zig.

+2 stars, pathfinding courtesy of Edsger Wybe Dijkstra.

See you tomorrow gamers.
