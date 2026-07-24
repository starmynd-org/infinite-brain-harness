# /promote-to-department: propose my work for the shared brain

Package something from an individual brain for the shared brain's maintainer to review. This is the only
road from individual work to the shared brain; nobody edits shared core directly.

## Steps

1. Ask, if not obvious: which piece of work do you want to propose, and in one sentence, why is it ready?
2. Create a dated candidate folder in the individual brain:
   `brains/individual-<name>/promote-queue/<YYYY-MM-DD>-<slug>/`, and copy the relevant files into it
   (copy, do not move).
3. Write `PROMOTION-NOTE.md` inside it: what this is, why it should be shared, the best-guess target path
   in the shared brain, and proposed-by plus today's date.
4. Commit the individual brain with `<name>: promotion candidate <slug>` (no push; `/sync` backs it up).
5. Tell the person to ping the shared brain's maintainer with the folder name. If approved, it ships to
   everyone. Offer to open a review branch on the shared brain right now instead, through `/sync`.
