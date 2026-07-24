# /workspace-help: explain this workspace

Explain the workspace to the person in warm, plain words. No git jargon, no file-tree dumps. Adapt to
what they ask; if they just typed `/workspace-help`, cover this:

1. **The brains.** `brains/` holds the brains you work across. The shared brain (a company or department
   brain) is the default, the canon everyone relies on. Your individual brain (`individual-<your-name>`)
   is where nothing you try can break anything for anyone. Rule of thumb: real shared work in the shared
   brain, ideas and experiments in your own.
2. **The everyday loop.** `/start` sets up or wakes up the machine. `/save` puts your name on your work.
   `/sync` backs it up over git and pulls the latest from every brain.
3. **What is free and what needs review.** Anything in your own brain is free; push it all day. Content
   you produce in the shared brain (outputs, session records) is free too. But a change to the shared
   brain's core (its knowledge, commands, or code) does not go straight to everyone; `/sync` puts it on a
   review branch and the brain's maintainer merges it. That protects everyone else who runs the same
   brain.
4. **Promotion.** If something in your own brain turns out great, `/promote-to-department` packages it for
   review. If approved, everyone gets it.
5. **Where each brain's commands come from.** `/sync` copies each brain's own commands, skills, and agents
   up into this workspace, so they show up as slash commands here after a Claude Code restart. A copied
   command runs against its brain. `.claude/CAPABILITIES.md` lists what each brain holds so you know which
   one to reach for.

Close by asking what they want to do first, and route them to the right brain for it.
