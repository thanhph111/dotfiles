# Config Docs

These docs explain how dotfiles decides what to apply.

Start here when you are changing profiles, packages, setup prompts, or machine entries.

## Map

| Question                                                       | Read                                                |
| -------------------------------------------------------------- | --------------------------------------------------- |
| What is the mental model?                                      | [Model](./model.md)                                 |
| Should this be a profile, machine, local answer, or user rule? | [Profiles and machines](./profiles-and-machines.md) |
| How do package settings and package lists work?                | [Packages](./packages.md)                           |
| Why did setup ask, and where did the answer go?                | [Local config](./local-config.md)                   |
| What should I edit for a common task?                          | [Examples](./examples.md)                           |

Short rule:

```text
broad defaults -> reusable profile -> named machine -> local or user override
```

More specific settings replace broader settings.
