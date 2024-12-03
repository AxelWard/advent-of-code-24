Alrighty today was much much better. To start off as soon as I saw the prompt I was pretty excited.
I really enjoyed building a compiler when I was in college, and this prompt immediately screamed
"I'm a little teeny baby compiler". Maybe at some point I should implement a toy compiler again,
just for shits and giggles this time.

Today I got to explore some new (to me) parts of Zig, got a bit more comfortable with arrays and
ArrayLists, but most of all was able to implement what I see as a pretty elegant solution very
quickly. Today only took me about 20 min, and that's including the fact that my LSP was basically non
functional (thank god for Google and Zig being open source, lol).

My solution is pretty straightforward. For part one I just iterated through the input buffer,
checked if it started with 'mul(' from my current location, then used a similar process to check the
validity of the rest of the command. For part 2 I basically did the same thing, but added do and
don't commands. Then I check which (if any) command was found, and do the corresponding operation. If
it was the 'mul(' command then I just ran the functionality from part one, and only added to the
total for part 2 if 'do()' was the last toggle command found.

Parsers, fun! A much more enthusiastic +2 stars today!

See you tomorrow gamers.
