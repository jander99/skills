# Advanced TypeScript Patterns Research

This document captures research findings on advanced TypeScript patterns, utility types, and best practices.

## Sources
- TypeScript Official Handbook (https://www.typescriptlang.org/docs/handbook/)
- TypeScript Release Notes (5.x series)

---

## 1. Generics

### Basic Generic Syntax
```typescript
function identity<Type>(arg: Type): Type {
  return arg;
}

// Two ways to call:
let output1 = identity<string>("myString");  // explicit
let output2 = identity("myString");          // type inference
```

### Generic Constraints
Constrain generics using `extends` to require certain properties:

```typescript
interface Lengthwise {
  length: number;
}

function loggingIdentity<Type extends Lengthwise>(arg: Type): Type {
  console.log(arg.length);  // Now we know it has .length
  return arg;
}

loggingIdentity({ length: 10, value: 3 });  // OK
loggingIdentity(3);  // Error: number doesn't have .length
```

### Using Type Parameters in Constraints
```typescript
function getProperty<Type, Key extends keyof Type>(obj: Type, key: Key) {
  return obj[key];
}

let x = { a: 1, b: 2 };
getProperty(x, "a");  // OK
getProperty(x, "m");  // Error: "m" not in "a" | "b"
```

### Generic Classes
```typescript
class GenericNumber<NumType> {
  zeroValue: NumType;
  add: (x: NumType, y: NumType) => NumType;
}
```

### Generic Parameter Defaults
```typescript
type Container<T = string> = { value: T };
const stringContainer: Container = { value: "hello" };
const numberContainer: Container<number> = { value: 42 };
```

---

## 2. Utility Types

### Transformation Types

| Type | Description |
|------|-------------|
| `Partial<T>` | Makes all properties optional |
| `Required<T>` | Makes all properties required |
| `Readonly<T>` | Makes all properties readonly |
| `Record<K, T>` | Constructs type with keys K and values T |

```typescript
interface Todo {
  title: string;
  description: string;
}

type PartialTodo = Partial<Todo>;
// { title?: string; description?: string; }

type RequiredTodo = Required<PartialTodo>;
// { title: string; description: string; }
```

### Selection Types

| Type | Description |
|------|-------------|
| `Pick<T, K>` | Picks specified properties from T |
| `Omit<T, K>` | Omits specified properties from T |
| `Extract<T, U>` | Extracts types from T assignable to U |
| `Exclude<T, U>` | Excludes types from T assignable to U |

```typescript
interface Todo {
  title: string;
  description: string;
  completed: boolean;
}

type TodoPreview = Pick<Todo, "title" | "completed">;
// { title: string; completed: boolean; }

type TodoInfo = Omit<Todo, "completed">;
// { title: string; description: string; }
```

### Nullability Types

| Type | Description |
|------|-------------|
| `NonNullable<T>` | Removes null and undefined from T |

```typescript
type T = NonNullable<string | number | undefined>;
// string | number
```

### Function Types

| Type | Description |
|------|-------------|
| `Parameters<T>` | Tuple of function parameter types |
| `ReturnType<T>` | Function return type |
| `ConstructorParameters<T>` | Tuple of constructor parameter types |
| `InstanceType<T>` | Instance type of constructor |

```typescript
function greet(name: string, age: number): string {
  return `Hello ${name}, age ${age}`;
}

type GreetParams = Parameters<typeof greet>;
// [string, number]

type GreetReturn = ReturnType<typeof greet>;
// string
```

### Promise Types

| Type | Description |
|------|-------------|
| `Awaited<T>` | Recursively unwraps Promise types |

```typescript
type A = Awaited<Promise<string>>;
// string

type B = Awaited<Promise<Promise<number>>>;
// number
```

### String Manipulation Types

| Type | Description |
|------|-------------|
| `Uppercase<S>` | Converts string to uppercase |
| `Lowercase<S>` | Converts string to lowercase |
| `Capitalize<S>` | Capitalizes first character |
| `Uncapitalize<S>` | Lowercases first character |

---

## 3. Mapped Types

### Basic Syntax
```typescript
type OptionsFlags<Type> = {
  [Property in keyof Type]: boolean;
};

interface Features {
  darkMode: () => void;
  newUserProfile: () => void;
}

type FeatureOptions = OptionsFlags<Features>;
// { darkMode: boolean; newUserProfile: boolean; }
```

### Mapping Modifiers
Add or remove `readonly` and `?` modifiers with `+` or `-`:

```typescript
// Remove readonly
type CreateMutable<Type> = {
  -readonly [Property in keyof Type]: Type[Property];
};

// Remove optional
type Concrete<Type> = {
  [Property in keyof Type]-?: Type[Property];
};
```

### Key Remapping via `as`
```typescript
type Getters<Type> = {
  [Property in keyof Type as `get${Capitalize<string & Property>}`]: 
    () => Type[Property]
};

interface Person {
  name: string;
  age: number;
}

type LazyPerson = Getters<Person>;
// { getName: () => string; getAge: () => number; }
```

### Filtering Keys
```typescript
type RemoveKindField<Type> = {
  [Property in keyof Type as Exclude<Property, "kind">]: Type[Property]
};
```

---

## 4. Conditional Types

### Basic Syntax
```typescript
SomeType extends OtherType ? TrueType : FalseType;
```

### Practical Example
```typescript
interface IdLabel { id: number; }
interface NameLabel { name: string; }

type NameOrId<T extends number | string> = 
  T extends number ? IdLabel : NameLabel;

function createLabel<T extends number | string>(value: T): NameOrId<T> {
  throw "unimplemented";
}

const a = createLabel("typescript");  // NameLabel
const b = createLabel(42);            // IdLabel
```

### Inferring Within Conditional Types
Use `infer` to extract types:

```typescript
type Flatten<Type> = Type extends Array<infer Item> ? Item : Type;

type Str = Flatten<string[]>;  // string
type Num = Flatten<number>;    // number

// Extract return type
type GetReturnType<Type> = 
  Type extends (...args: never[]) => infer Return ? Return : never;
```

### Distributive Conditional Types
Conditional types distribute over unions:

```typescript
type ToArray<Type> = Type extends any ? Type[] : never;

type StrArrOrNumArr = ToArray<string | number>;
// string[] | number[]  (NOT (string | number)[])

// Prevent distribution with brackets:
type ToArrayNonDist<Type> = [Type] extends [any] ? Type[] : never;
```

---

## 5. Type Guards and Narrowing

### typeof Guards
```typescript
function padLeft(padding: number | string, input: string): string {
  if (typeof padding === "number") {
    return " ".repeat(padding) + input;
  }
  return padding + input;
}
```

### Truthiness Narrowing
```typescript
function printAll(strs: string | string[] | null) {
  if (strs && typeof strs === "object") {
    for (const s of strs) {
      console.log(s);
    }
  }
}
```

### Equality Narrowing
```typescript
function example(x: string | number, y: string | boolean) {
  if (x === y) {
    // Both must be string here
    x.toUpperCase();
  }
}
```

### The `in` Operator
```typescript
type Fish = { swim: () => void };
type Bird = { fly: () => void };

function move(animal: Fish | Bird) {
  if ("swim" in animal) {
    return animal.swim();
  }
  return animal.fly();
}
```

### instanceof Narrowing
```typescript
function logValue(x: Date | string) {
  if (x instanceof Date) {
    console.log(x.toUTCString());
  } else {
    console.log(x.toUpperCase());
  }
}
```

### User-Defined Type Guards (Type Predicates)
```typescript
function isFish(pet: Fish | Bird): pet is Fish {
  return (pet as Fish).swim !== undefined;
}

// Usage
if (isFish(pet)) {
  pet.swim();  // TypeScript knows pet is Fish
}

// Filter arrays
const fishArray: Fish[] = zoo.filter(isFish);
```

### Discriminated Unions
Use a common property with literal types to narrow:

```typescript
interface Circle {
  kind: "circle";
  radius: number;
}

interface Square {
  kind: "square";
  sideLength: number;
}

type Shape = Circle | Square;

function getArea(shape: Shape) {
  switch (shape.kind) {
    case "circle":
      return Math.PI * shape.radius ** 2;
    case "square":
      return shape.sideLength ** 2;
  }
}
```

### Exhaustiveness Checking with `never`
```typescript
function getArea(shape: Shape) {
  switch (shape.kind) {
    case "circle":
      return Math.PI * shape.radius ** 2;
    case "square":
      return shape.sideLength ** 2;
    default:
      const _exhaustiveCheck: never = shape;
      return _exhaustiveCheck;
  }
}
// Adding Triangle to Shape without handling it will cause error
```

---

## 6. Declaration Merging

### Interface Merging
```typescript
interface Box {
  height: number;
  width: number;
}

interface Box {
  scale: number;
}

// Merged to:
// interface Box {
//   height: number;
//   width: number;
//   scale: number;
// }
```

### Namespace Merging
```typescript
namespace Animals {
  export class Zebra {}
}

namespace Animals {
  export interface Legged {
    numberOfLegs: number;
  }
  export class Dog {}
}

// Animals now has Zebra, Dog, and Legged
```

### Module Augmentation
Extend existing modules:

```typescript
// Augment a module
declare module "./observable" {
  interface Observable<T> {
    map<U>(f: (x: T) => U): Observable<U>;
  }
}

// Global augmentation
declare global {
  interface Array<T> {
    toObservable(): Observable<T>;
  }
}
```

---

## 7. The `satisfies` Operator

Introduced in TypeScript 4.9. Validates type without widening:

```typescript
type Colors = "red" | "green" | "blue";
type RGB = [red: number, green: number, blue: number];

const palette = {
  red: [255, 0, 0],
  green: "#00ff00",
  blue: [0, 0, 255]
} satisfies Record<Colors, string | RGB>;

// Type is preserved:
const greenLength = palette.green.length;  // OK, knows it's string
const redValue = palette.red[0];           // OK, knows it's RGB tuple
```

**Use Cases:**
- Validate object literals match a type
- Preserve inferred literal types
- Better error messages at declaration site

---

## 8. Template Literal Types

Create types from string patterns:

```typescript
type EventName<T extends string> = `${T}Changed`;

type PersonEvents = EventName<"name" | "age">;
// "nameChanged" | "ageChanged"

// Combine with mapped types
type Getters<T> = {
  [K in keyof T as `get${Capitalize<string & K>}`]: () => T[K]
};
```

---

## 9. Variance Annotations (`in`/`out`)

TypeScript 4.7+ allows explicit variance annotations:

```typescript
// Contravariant (in) - consumes T
interface Consumer<in T> {
  consume: (arg: T) => void;
}

// Covariant (out) - produces T  
interface Producer<out T> {
  make(): T;
}

// Invariant (in out) - both consumes and produces
interface ProducerConsumer<in out T> {
  consume: (arg: T) => void;
  make(): T;
}
```

**Important:** Only use when you've identified a specific need. TypeScript infers variance automatically in most cases.

---

## 10. Strict Mode Best Practices

### Essential Strict Options
```json
{
  "compilerOptions": {
    "strict": true,
    "noImplicitAny": true,
    "strictNullChecks": true,
    "strictFunctionTypes": true,
    "strictBindCallApply": true,
    "strictPropertyInitialization": true,
    "noImplicitThis": true,
    "alwaysStrict": true
  }
}
```

### Additional Recommended Options
```json
{
  "noUncheckedIndexedAccess": true,
  "noImplicitReturns": true,
  "noFallthroughCasesInSwitch": true,
  "noImplicitOverride": true,
  "exactOptionalPropertyTypes": true
}
```

---

## 11. Avoiding `any`

### Always Prefer These Instead:

| Instead of `any` | Use |
|------------------|-----|
| Unknown type | `unknown` |
| Any object | `object` or `Record<string, unknown>` |
| Any array | `unknown[]` |
| Any function | `(...args: unknown[]) => unknown` |
| Placeholder during development | `TODO: fixme` comment with `unknown` |

### Safe Unknown Pattern
```typescript
function processValue(value: unknown): string {
  // Must narrow before use
  if (typeof value === "string") {
    return value.toUpperCase();
  }
  if (typeof value === "number") {
    return value.toString();
  }
  throw new Error("Unsupported type");
}
```

### Type Assertion Best Practices
```typescript
// Avoid:
const data = response as any;

// Better:
const data = response as unknown as MyType;

// Best: Use type guard
function isMyType(x: unknown): x is MyType {
  return typeof x === "object" && x !== null && "property" in x;
}
```

---

## 12. NoInfer Utility Type

Introduced in TypeScript 5.4. Blocks inference in specific positions:

```typescript
function createStreetLight<C extends string>(
  colors: C[],
  defaultColor?: NoInfer<C>
) {
  // ...
}

createStreetLight(["red", "yellow", "green"], "red");    // OK
createStreetLight(["red", "yellow", "green"], "blue");   // Error!
```

---

## 13. Common Advanced Patterns

### Deep Partial
```typescript
type DeepPartial<T> = {
  [P in keyof T]?: T[P] extends object ? DeepPartial<T[P]> : T[P];
};
```

### Deep Readonly
```typescript
type DeepReadonly<T> = {
  readonly [P in keyof T]: T[P] extends object ? DeepReadonly<T[P]> : T[P];
};
```

### Mutable from Readonly
```typescript
type Mutable<T> = {
  -readonly [P in keyof T]: T[P];
};
```

### Optional Keys Only
```typescript
type OptionalKeys<T> = {
  [K in keyof T]-?: {} extends Pick<T, K> ? K : never
}[keyof T];
```

### Required Keys Only
```typescript
type RequiredKeys<T> = {
  [K in keyof T]-?: {} extends Pick<T, K> ? never : K
}[keyof T];
```

### Function Overload Types
```typescript
type Overloads<T> = T extends {
  (...args: infer A1): infer R1;
  (...args: infer A2): infer R2;
} ? [(...args: A1) => R1, (...args: A2) => R2] : never;
```

---

## References

- [TypeScript Handbook - Generics](https://www.typescriptlang.org/docs/handbook/2/generics.html)
- [TypeScript Handbook - Utility Types](https://www.typescriptlang.org/docs/handbook/utility-types.html)
- [TypeScript Handbook - Mapped Types](https://www.typescriptlang.org/docs/handbook/2/mapped-types.html)
- [TypeScript Handbook - Conditional Types](https://www.typescriptlang.org/docs/handbook/2/conditional-types.html)
- [TypeScript Handbook - Narrowing](https://www.typescriptlang.org/docs/handbook/2/narrowing.html)
- [TypeScript Handbook - Declaration Merging](https://www.typescriptlang.org/docs/handbook/declaration-merging.html)
- [TypeScript Release Notes](https://www.typescriptlang.org/docs/handbook/release-notes/overview.html)
