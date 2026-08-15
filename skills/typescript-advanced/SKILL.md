---
name: typescript-advanced
description: Design, implement, refactor, and debug advanced TypeScript patterns including generics, utility types, mapped types, conditional types, type guards, discriminated unions, and strict mode configuration. Use when writing type-safe code, fixing type errors, or improving type inference.
license: MIT
metadata:
  version: 1.0.0
  audience: developers
  workflow: frontend-development
---

# TypeScript Advanced Patterns

Expert guidance for writing type-safe TypeScript code using advanced type system features.

## What I Do

- Design generic types with constraints, defaults, and inference
- Apply utility types (Partial, Pick, Omit, Record, Required, Readonly)
- Create custom mapped and conditional types
- Implement type guards and discriminated unions
- Configure strict mode and debug type errors
- Augment modules and merge declarations

## When to Use Me

Use this skill when you:
- Create generic functions, classes, or type-safe APIs
- Fix, debug, or resolve TypeScript type errors
- Write custom mapped or conditional types
- Add type guards for runtime narrowing
- Configure or troubleshoot strict mode settings
- Avoid `any` and improve type safety

## Generic Patterns

```typescript
// Constrain generic to require properties
function loggingIdentity<T extends { length: number }>(arg: T): T {
  console.log(arg.length);
  return arg;
}

// Type parameter constrained by another
function getProperty<T, K extends keyof T>(obj: T, key: K): T[K] {
  return obj[key];
}

// Default type parameter
type Container<T = string> = { value: T };
```

## Utility Types

```typescript
interface User { id: number; name: string; email: string; }

type PartialUser = Partial<User>;           // All optional
type RequiredUser = Required<PartialUser>;  // All required
type ReadonlyUser = Readonly<User>;         // All readonly
type UserPreview = Pick<User, "id" | "name">;
type UserWithoutEmail = Omit<User, "email">;

// Function types - define the function first
function fetchUser(id: number): Promise<User> { /* ... */ }

type Params = Parameters<typeof fetchUser>;     // [number]
type Return = ReturnType<typeof fetchUser>;     // Promise<User>
type Unwrapped = Awaited<ReturnType<typeof fetchUser>>;  // User
```

## Type Guards

```typescript
// typeof and instanceof narrowing
function process(value: string | number) {
  if (typeof value === "string") return value.toUpperCase();
  return value.toFixed(2);
}

// User-defined type predicate
function isFish(pet: Fish | Bird): pet is Fish {
  return (pet as Fish).swim !== undefined;
}

// Discriminated unions with exhaustiveness checking
interface Circle { kind: "circle"; radius: number; }
interface Square { kind: "square"; sideLength: number; }
type Shape = Circle | Square;

function getArea(shape: Shape): number {
  switch (shape.kind) {
    case "circle": return Math.PI * shape.radius ** 2;
    case "square": return shape.sideLength ** 2;
    default: const _: never = shape; return _;  // Exhaustiveness
  }
}
```

## Mapped Types

```typescript
// Transform all properties
type OptionsFlags<T> = { [P in keyof T]: boolean };

// Remove modifiers
type Mutable<T> = { -readonly [P in keyof T]: T[P] };
type Concrete<T> = { [P in keyof T]-?: T[P] };

// Key remapping with template literals
type Getters<T> = {
  [K in keyof T as `get${Capitalize<string & K>}`]: () => T[K]
};
```

## Template Literal Types

Template literal types let you compose string-literal types the same way
you compose template literals at runtime. They shine for typed event names,
CSS-in-TS APIs, and route builders.

```typescript
// Type-safe event names: onClick, onFocus, on...
type EventName<T extends string> = `on${Capitalize<T>}`;
type ButtonEvents = EventName<"click" | "focus" | "blur">;
//   → "onClick" | "onFocus" | "onBlur"

// Combine: build CSS prop from unit
type CSSValue = `${number}${"px" | "rem" | "em"}`;
// 50px, 1.5rem, 2em — all valid; "50" alone is not

// Real-world: route paths from a list of resources + actions
type Resource = "users" | "posts" | "comments";
type Action = "list" | "create" | "edit";
type ApiPath = `/api/${Resource}/${Action}`;
// "/api/users/list" | "/api/users/create" | ... | "/api/comments/edit"
```

**Built-in template-literal helpers** (TypeScript 4.1+):

```typescript
Uppercase<"foo">       // "FOO"
Lowercase<"FOO">       // "foo"
Capitalize<"foo">      // "Foo"
Uncapitalize<"Foo">    // "foo"
```

**Combine with mapped types to drive string-keyed APIs:**

```typescript
type PropEventListeners<T> = {
  [K in keyof T as `${string & K}Changed`]?: (newValue: T[K]) => void;
};

interface Form {
  email: string;
  age: number;
}
// PropEventListeners<Form> gives you:
//   emailChanged?: (newValue: string) => void
//   ageChanged?:    (newValue: number) => void
```

## Declaration Merging

TypeScript merges multiple declarations that share a name. The most common
forms are **interface merging** and **module augmentation**.

### Interface Merging

When two interfaces with the same name are exported from the same module,
TypeScript combines their members into one. Useful for extending a third-
party interface (where `extends` is not an option):

```typescript
// Original
interface User {
  id: number;
  name: string;
}

// Augment — same name, same module, members combine
interface User {
  email: string;
  createdAt: Date;
}

const u: User = {
  id: 1,
  name: "Ada",
  email: "ada@example.com",
  createdAt: new Date(),
};
// All four fields required.
```

### Module Augmentation

To add fields to an existing module's exported types, declare the module
again in a file that's part of the compilation:

```typescript
// types.d.ts — ambient declaration merges with @types/express
declare module "express" {
  interface Request {
    userId?: string;       // augmented onto Express.Request
  }
}

// Usage: anywhere in the codebase, after this file is in tsconfig
app.use((req, _res, next) => {
  console.log(req.userId);   // typed as string | undefined
  next();
});
```

**Rules:**
- Both declarations must be in the same module (file) **or** the augmenting
  file must be loaded by the compiler (ambient `.d.ts` or referenced via
  `include`).
- You can only merge interfaces (and namespace-style merges with classes),
  not type aliases.
- Conflicting member types in the same interface will error.

> Use module augmentation sparingly — over-augmenting makes a type harder
> to reason about. Prefer wrapping (e.g., a `RequestWithUser` type) when
> the augmented behavior is local.

## Conditional Types

```typescript
// Basic conditional
type IsString<T> = T extends string ? true : false;

// Inferring types
type Flatten<T> = T extends Array<infer Item> ? Item : T;
type GetReturnType<T> = T extends (...args: any[]) => infer R ? R : never;

// Distributive behavior (over unions)
type ToArray<T> = T extends any ? T[] : never;
type Result = ToArray<string | number>;  // string[] | number[]

// Prevent distribution (wrap in tuple)
type ToArrayNonDist<T> = [T] extends [unknown] ? T[] : never;
type Result = ToArrayNonDist<string | number>;  // (string | number)[]
```

## Context7 Integration

For up-to-date TypeScript documentation, use Context7 MCP server:
- Query: "TypeScript generics constraints" | Library: /microsoft/typescript
- Query: "TypeScript utility types" | Library: /microsoft/typescript
- Query: "TypeScript conditional types infer" | Library: /microsoft/typescript

## Common Errors

**"Property does not exist on type"** - Use `in` operator or type guard:
```typescript
if ("a" in obj) { console.log(obj.a); }
```

**"Type is not assignable to type 'never'"** - Missing switch case:
```typescript
// Add missing case or default with never check
```

**"Object is possibly 'undefined'"** - Use optional chaining or type guard:
```typescript
console.log(user.address?.city);
if (user.address) { console.log(user.address.city); }
```

**Avoiding `any`:**
```typescript
// Use unknown instead of any
function processData(data: unknown): string {
  if (typeof data === "string") return data.toUpperCase();
  throw new Error("Unsupported type");
}
type AnyObject = Record<string, unknown>;
type AnyFunction = (...args: unknown[]) => unknown;
```

## Strict Mode Configuration

```json
{
  "compilerOptions": {
    "strict": true,
    "noImplicitAny": true,
    "strictNullChecks": true,
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true
  }
}
```

## Modern TypeScript (4.9+)

```typescript
// satisfies - validate type without widening
const config = {
  port: 8080,
  host: "localhost"
} satisfies Record<string, string | number>;
// config.port is number, not string | number

// const type parameters (TS 5.0+)
function createArray<const T extends readonly unknown[]>(items: T): T {
  return items;
}
const arr = createArray([1, 2, 3]);  // readonly [1, 2, 3], not number[]

// using declarations (TS 5.2+)
async function processFile() {
  using file = await openFile("data.txt");
  // file automatically disposed at end of scope
}
```

## Related Skills

- [angular-components](../angular-components/SKILL.md) - Angular component patterns
- [angular-state](../angular-state/SKILL.md) - State management with TypeScript

## References

| Reference | Use When |
|-----------|----------|
| [research.md](references/research.md) | Deep dive into patterns and examples |
| [TypeScript Handbook](https://www.typescriptlang.org/docs/handbook/) | Official documentation |
