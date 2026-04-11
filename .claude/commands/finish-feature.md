Run the standard post-feature checklist in order, fixing any issues before moving on:

1. **`flutter analyze`** — fix all warnings and errors before proceeding.
2. **Run tests** — run `flutter test` and fix any failing tests before proceeding.
3. **`dart format .`** — format all Dart files; stage the result.
4. **Update `prompts.md`** — append only the relevant prompt entry/entries (continue the existing numbering; use the marker defined in `prompts.md` for the currently active LLM); do not add an additional description of what was built or fixed.
5. **Commit** — commit all staged changes with a concise message as the currently active LLM.
