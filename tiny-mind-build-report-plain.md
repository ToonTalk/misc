# Building Tiny Mind — A Plain-Language Report

## What we were trying to do

Tiny Mind is a set of small web pages for playing with a tiny artificial "mind." One page, the Nursery, lets a child invent a character — say, a unicorn named Sisi who eats rainbows and lives in a magic tree — write it a little storybook, and then watch a very small AI learn to tell stories about that character, live, in the browser. A second page, the Microscope, lets you look inside any such mind and see what it is paying attention to. A third, the Hunt, turns the whole thing into a treasure hunt: ask the mind a question, get clues about where inside it a fact might be stored, and then test each clue to see if it was right.

These pages already worked when you opened them on your own computer or put them on a website. The job that started this session sounded simple: make a version that runs inside a Claude "artifact" — the little interactive panel that appears next to a Claude conversation — so a teacher or a family could just open it and use it, no setup.

## The simple job that wasn't

At first the job really did look small. The pages were already built in a way that fit the new home almost perfectly. There was one thing to change — how the app remembers your work between visits — and that was quickly done.

And then the new home started saying no. The artifact panel is a deliberately locked-down space, for safety, and it turned out to forbid a whole series of things the app quietly relied on. The catch was that almost none of these rules were written down anywhere we could read in advance. We discovered each one the way you discover a low doorway: by walking into it. Over and over, the way forward was for the app to be run, for an error to appear, and for that error to be pasted back so we could figure out which wall we had just hit.

That is the honest story of the first half of this work: not a clean plan executed, but a map drawn by bumping into things in the dark.

## The walls, one by one

The first and worst wall stopped the app cold. The way it does its heavy thinking — training the little mind — was simply not allowed to start in the locked room, and the whole page died the moment it opened. The written notes we had actually claimed this would work; it didn't, because no one had ever truly tried it in the real setting. (I had even guessed wrong about *which* part would break first.) The fix was to teach the app a second way of doing its heavy thinking that the locked room does permit — slower, because it now has to share attention with the screen, but working.

Other walls followed. Dropping two files onto the page one after another lost the second file, because of a timing quirk in how the browser hands over dropped files. Saving a finished mind to disk was blocked in a way that led me, at one point, to build an awkward two-step "click here, now click there" dance — which Ken rightly rejected, twice, and which turned out to be unnecessary once I understood the rule properly. Reaching out to other companies' AI services was blocked entirely, so a key you typed in appeared to do nothing (it was being used; the request just couldn't leave the room). And opening the file by double-clicking it on your own machine fails for a subtle security reason, so the combined app has to be served through a small local web server instead.

None of these were the app being wrong. They were the app meeting an environment with unfamiliar rules, and each one had to be handled specifically.

## Putting three rooms under one roof

Along the way the three separate pages were combined into a single file with tabs — a Nursery tab, a Microscope tab, a Hunt tab — and a shared shelf where the models live. This was done carefully: each of the three original pages runs untouched inside its own protected compartment, with a small translator between it and the shared shell so that everything still works without rewriting the parts that already worked. The payoff is that the whole journey now flows in one place: raise a mind in the Nursery, and it appears automatically on the shelf, one click away from being examined in the Microscope or hunted through in the Hunt. To keep it forgiving, you can feed it a single zip bundle, a folder, or loose files, and it sorts out which is which by actually looking inside them rather than trusting their names.

## When "does it work" became "does it make sense"

Once the app ran, the nature of the problems changed completely, and this is the more interesting half of the story.

The bugs stopped being "this doesn't work" and became "this works, but it's confusing." Again and again, the confusion had the same root: two genuinely different things were sharing one name, or sitting in the same spot on the screen, so they looked like one thing. A line on a graph meant to show the mind *forgetting* its ordinary language needed a different kind of story-data than the child's own stories — and until that was made clear, its absence looked like a malfunction. The "detective" that offers clues in the Hunt is a large outside AI making *guesses*, while the numbers right next to it are the tiny mind's own *measurements* — but because they shared a panel, it looked as if the detective was producing the numbers. And a probability shown as "8.9e-2%" meant nothing to a child; shown as "1 in 1,124," it means something immediately.

The deepest example of this was a genuine little scientific puzzle. The trained Sisi mind, asked to finish "Sisi lives in a magic ___," answered "tree" almost every time. Asked to finish "Sisi is a nice ___," it answered "unicorn" almost never — even though it had been taught both facts about equally. Why would it confidently know one and seem to have no idea about the other?

The answer turned out to be revealing. "Tree" is a common little word the mind handles in one piece. "Unicorn" is a rarer word that the mind has to spell out in several pieces, and the way the Hunt scored the answer multiplied the confidence of each piece together — so a rare, many-piece word looks hopeless even when the mind can happily say it out loud. On top of that, "magic" is an unusual word that, in these stories, is almost always followed by "tree," so the mind can nail it from that one word alone. "Nice," by contrast, is an everyday word that can be followed by anything, so it takes far more to pin down "unicorn" after it. The fact wasn't really stored "about Sisi" at all — "magic tree" is just a word-pair the mind would complete for anyone.

That last point matters for what the Hunt is even trying to teach. The Hunt assumes a fact lives in a findable *place* inside the mind that you can switch off to prove you found it. That is cleanly true only for certain kinds of facts. So the app grew a new tool that lets a child test exactly this — swap the character's name and see whether the answer changes; if it doesn't, the fact isn't really about that character, and there's no treasure to find — and gentle guidance toward the kinds of facts that make for a good, winnable hunt. Whether to smooth this over or to *teach* it as one of the real lessons is a genuine open choice, not a defect.

## What this was, in the end

Two things stand out about the process. The first is how much of it was empirical rather than planned — a conversation with a system whose rules had to be learned by trial, with the person building it and the AI helping build it taking turns spotting what had just gone wrong. The second is a pattern worth remembering: for a tool whose whole purpose is to make something understandable, the hardest bugs were not about whether it *worked* but about whether it *made sense* — and the most reliable sign that something was unclear was that it confused the very person who built it. A ten-year-old was never going to file that bug report. When the mechanism puzzles its own author, that is the warning worth listening to, and this app is close because we kept listening to it.
