# Anti-patterns

Things to avoid, and the pattern to use instead.

- Business logic in a controller. Put it in the service layer.
- Data access outside a repository. Always go through the repository interface.
- Passing domain entities across a layer boundary. Use a DTO at every boundary.
- Type or mode conditionals. Use the strategy pattern.
- Service locators or field injection. Use constructor-based dependency injection.
- Catching an exception to swallow it or convert it to a string. Raise a typed domain error and map it in one place.
- Logging secrets or sensitive fields. Never log keys, tokens, or credentials.
- Magic values. Name a constant.
- Dead code left commented out. Delete it.
- A change that mixes refactoring with a feature. Split into separate atomic tasks and commits.
- An interface with a single implementation, or a factory for a single product. Add the abstraction only when a second case exists.
- Inventing an API or dependency that is not in the codebase or the plan. Check first.
- Reformatting code unrelated to the task. Never touch unrelated lines.
