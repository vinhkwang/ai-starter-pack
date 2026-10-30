# Architecture

## Layering

Requests flow through four layers only, in order:

Controller -> Service -> Repository -> Database

Each layer depends only on the layer directly below it. Dependencies point inward. No layer may skip or bypass the one below it.

## Layer responsibilities and prohibitions

### Controller

Responsible for receiving requests, validating and parsing input via DTOs, calling exactly one service method, and mapping errors to responses.

Prohibited: business logic, direct repository or database access, composing multiple services.

### Service

Responsible for business rules, orchestrating repositories, applying strategies, and raising typed domain errors.

Prohibited: HTTP or transport concerns, reading request objects, direct database access.

### Repository

Responsible for persistence of one aggregate, exposing an interface in the domain layer and an implementation in the data layer.

Prohibited: business logic, returning framework-specific query objects across the boundary.

### Database

Responsible for storage and constraints.

Prohibited: business logic in stored procedures or triggers where avoidable.

## Required patterns

- DTO at every layer boundary. No layer receives or returns a domain entity from another layer directly.
- One repository interface per aggregate. Implementations live outside the domain layer.
- Strategy pattern instead of type or mode conditionals.
- Constructor-based dependency injection only. No service locators, no field injection.

## Errors

Typed domain errors raised by services. Map them to responses in one place, at the controller or a single error mapper.

## Folder layout

Guidance only, not a scaffold. Adapt to the idioms of the chosen stack.

controllers/ services/ repositories/ dtos/ strategies/ domain/ config/
