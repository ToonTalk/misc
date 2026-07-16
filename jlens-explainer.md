# How the Jacobian Lens Is Computed

*For readers who know some linear algebra (vectors, matrices,
matrix-times-vector), some calculus (what a derivative is), and some coding.*

## The problem: the model's thoughts aren't written in words

At every layer, for every token, a transformer carries a **hidden vector**:
a list of numbers. For the story model we use, that's 768 numbers per token
per layer, at each of 12 layers. Somewhere in those numbers, the model is
keeping track of who the characters are, what just happened, and where the
story is heading. But the vector isn't written in English — it's just
numbers. The Jacobian lens is an instrument for translating those numbers
into words: **"which words is this hidden vector pushing the model toward
saying — now, or a few sentences from now?"**

## The last layer is already readable

The model's final step is simple. It takes the last layer's hidden vector
`h_final` (768 numbers) and multiplies it by a big matrix `W_U` (the
**unembedding matrix**, one row per vocabulary word — 32,000 rows here):

```
scores = W_U @ h_final        # one score per vocabulary word
```

The highest-scoring word is what the model says next. So the final layer
comes with its own built-in translator: `W_U`.

The obvious trick — called the **logit lens** — is to point that same
translator at a *middle* layer: `scores = W_U @ h_middle`. Sometimes this
works. But often it doesn't, because middle-layer vectors still have many
layers of processing ahead of them. It's like judging an unfinished
drawing as if it were the final picture: the early sketch lines don't
mean the same thing as the finished strokes.

## The fix: transport first, then translate

The Jacobian lens adds one step. Before applying `W_U`, it **transports**
the middle-layer vector into the final layer's coordinate system —
answering "what will this vector have turned into, on average, by the time
the model finishes processing?" — and only then translates:

```
scores = W_U @ (J @ h_middle)
```

`J` is one matrix per layer, and everything interesting is in how it's
built.

## Where calculus comes in

Think of everything between layer L and the model's final output as one
big function `F`: it takes a 768-dimensional vector in and produces
768-dimensional vectors out (at the current token and, through attention,
at all the *later* tokens too).

For an ordinary function `y = f(x)`, the derivative answers: if I nudge
`x` a little, how much does `y` move? `Δy ≈ f'(x) · Δx`.

For a vector-in, vector-out function, the same question has a matrix
answer. The **Jacobian** `J` is the grid of all the partial derivatives:

```
J[i][j] = ∂ output_i / ∂ input_j
```

and the small-nudge rule becomes matrix multiplication:

```
Δoutput ≈ J @ Δinput
```

Column `j` of `J` says: "nudge input coordinate `j`, and here's how every
output coordinate responds." So the Jacobian of `F` is exactly the
transport we wanted: it converts middle-layer directions into
final-layer directions.

## Why we average

One Jacobian, computed on one sentence at one position, only describes
*that* sentence. The word "bank" gets processed differently in "river
bank" than in "bank robbery" — a single context's Jacobian mixes the
general meaning of a direction with the accidents of that one prompt.

So the lens is the **average** Jacobian: run the model over a few hundred
ordinary texts, compute the Jacobian at every position, and average.
What survives the averaging is the context-general part: "vectors
pointing this way tend, across all kinds of text, to make the model say
*dragon* eventually." That's why the lens reads out what a vector is
**poised** to make the model say, not just what one sentence happens to
do with it.

Two details hide in "eventually":

- The outputs we differentiate against include the final vectors at the
  **current and all later positions**. That's how "later" gets into the
  lens: attention carries a middle-layer vector's influence forward to
  future tokens.
- We don't have to exclude *earlier* positions by hand. Information in a
  causal transformer only flows forward, so the derivative of an earlier
  output with respect to a later hidden vector is automatically zero.

## How to actually compute it: backprop, run sideways

Computing a 768×768 Jacobian sounds expensive, but the training machinery
already does the hard part. **Backpropagation** computes, in a single
backward pass, the derivative of *one chosen number* with respect to
*every* hidden vector in the whole network at once.

So: choose the number to be "coordinate `i` of the final vector, summed
over every position." One backward pass then hands you **row `i` of the
Jacobian at every layer and every position simultaneously.** Do that 768
times — once per coordinate — and you have the whole matrix, everywhere.

```
# FITTING THE LENS
# model: L layers, hidden size d (=768), vocab V (=32000)
# returns J[layer]: one d x d matrix per layer

def fit_jlens(model, texts):                 # texts: a few hundred is enough
    J = [zeros(d, d) for each layer]
    n = 0                                    # how many positions we averaged

    for text in texts:
        h = forward(model, text, cache=True) # remember every hidden vector
        T = number_of_tokens(text)

        for i in range(d):                   # one row of the Jacobian at a time
            # ask about coordinate i of the FINAL vector, at ALL positions
            seed = zeros_like(h.final)       # shape: T x d
            seed[:, i] = 1
            g = backprop(model, seed)        # ONE backward pass
            # g[layer][t] is a d-vector: row i of the Jacobian
            # from (layer, position t) to the summed final outputs
            for layer in range(L):
                for t in range(T):
                    J[layer][i, :] += g[layer][t]
        n += T

    return [J[layer] / n for each layer]     # the average Jacobian
```

That's the whole fit. (Real implementations speed this up — for example
by batching the 768 seeds, or by sampling random seed directions instead
of stepping through coordinates one by one — but nothing conceptual
changes.) The result is compact: 12 matrices of 768×768 numbers, about
7 million numbers total — far smaller than the model itself. Fit once,
use forever.

## Using the lens

```
# READING A HIDDEN VECTOR
def read(model, J, text, layer, position, k=10):
    h = forward(model, text, cache=True)
    v = J[layer] @ h[layer][position]   # transport to the final layer's basis
    v = final_norm(v)                   # the model's own last normalization step
    scores = W_U @ v                    # translate: one score per word
    return top_k_words(scores, k)
```

Point it at layer 6, position 40 of a story, and it returns something
like: `dragon, cave, scared, ran` — words the model is holding ready,
even though none of them may have been said yet.

One elegant check that the idea hangs together: at the final layer there
is nothing left to transport, so `J` is the identity matrix — and the
J-lens reduces exactly to the logit lens. The logit lens is the special
case `J = I`; the Jacobian lens is what you get when you stop pretending
every layer is the last one.

## From lens to "J-space"

The research paper takes one more step. Instead of just ranking words, it
asks: can this hidden vector be *rebuilt* as a small recipe of
word-directions? Each vocabulary word `w` has a direction in hidden space
(the direction that most raises `w`'s score through the lens). A greedy
loop finds the recipe:

```
residual = h
recipe = []
repeat ~25 times:
    w = word whose direction best matches residual
    a = how strongly it matches (keep only if a > 0)
    recipe.append((w, a))
    residual -= a * direction(w)
```

The small set of active word-directions — "0.8 × dragon + 0.5 × scared +
0.3 × cave..." — is what the paper calls the **J-space**: the slice of the
model's hidden state that can be summarized as a short bag of sayable
concepts. The rest of the vector (most of it!) is machinery that never
gets put into words.

## Honest limitations

- **It's a linear approximation.** The Jacobian is a first-order
  (small-nudge) description of a very nonlinear machine, averaged over
  contexts. It's validated by intervention: inject or swap a word's
  direction and check the model's later output actually changes
  accordingly.
- **One word = one token, mostly.** The lens has one direction per
  vocabulary *token*. Words that the tokenizer splits into pieces are
  hard to see: in our story model, *dragon* is one token and shows up
  beautifully, but *Lily* splits into ` L` + `ily` — so the lens shows a
  suspicious ` L` lighting up whenever Lily is on the model's mind.
- **It only sees what's poised for words.** Anything the model represents
  in a form that never feeds toward the vocabulary is invisible to this
  instrument — which is part of what makes the visible slice so
  interesting.
