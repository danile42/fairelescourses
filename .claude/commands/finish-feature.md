Run the standard post-feature checklist in order, fixing any issues before moving on:

1. **`flutter analyze`** — fix all warnings and errors before proceeding.
2. **Run tests** — run `flutter test` and fix any failing tests before proceeding.
3. **`dart format .`** — format all Dart files; stage the result.
4. **Update `prompts.md`** — append a numbered entry describing what was just built or fixed (continue the existing numbering; mark Junie's entries with **[J]**).
5. **Commit** — commit all staged changes with a concise message.
