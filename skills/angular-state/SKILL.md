---
name: angular-state
description: Create, implement, debug, refactor, and optimize Angular state management with RxJS observables, subjects, signals, operators, and reactive patterns. Fix memory leaks, manage subscriptions, handle async data streams. Use when building reactive Angular components, services, or stores.
license: MIT
metadata:
  version: 1.0.0
  audience: developers
  workflow: frontend-development
---

# Angular State Management & RxJS

Implement reactive state management in Angular using RxJS observables, subjects, signals, and patterns that prevent memory leaks.

## What I Do

- Design state management with BehaviorSubject, signals, or NgRx
- Write RxJS operator pipelines (switchMap, mergeMap, combineLatest)
- Fix memory leaks with proper subscription cleanup patterns
- Convert between signals and observables (toSignal/toObservable)
- Debug async data flows and race conditions
- Implement caching, polling, and optimistic updates

## When to Use Me

Use this skill when you:
- Create or refactor reactive state management
- Write or debug RxJS operator chains
- Fix memory leaks from unmanaged subscriptions
- Choose between signals, BehaviorSubject, or NgRx
- Implement switchMap, mergeMap, exhaustMap, or concatMap
- Convert signals to observables or vice versa

## RxJS Operator Selection

| Operator | Behavior | Use Case |
|----------|----------|----------|
| `switchMap` | Cancels previous | Typeahead, search, route params |
| `mergeMap` | All parallel | Writes, parallel requests |
| `concatMap` | Sequential queue | Ordered operations |
| `exhaustMap` | Ignores new | Prevent double-submit |

```typescript
// switchMap - Cancel previous on new input
searchControl.valueChanges.pipe(
  debounceTime(300),
  switchMap(term => this.searchService.search(term))
).subscribe(results => this.results = results);

// exhaustMap - Ignore clicks during submission
submitBtn$.pipe(
  exhaustMap(() => this.formService.submit(this.form.value))
).subscribe();
```

## Subject Types

| Type | Replay | Use Case |
|------|--------|----------|
| `Subject` | None | Event bus, actions |
| `BehaviorSubject` | Last value | Current state (most common) |
| `ReplaySubject` | N values | Late subscribers need history |

```typescript
// BehaviorSubject for state
private userSubject = new BehaviorSubject<User | null>(null);
user$ = this.userSubject.asObservable();
```

## Memory Leak Prevention

### takeUntilDestroyed (Preferred)
```typescript
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';

@Component({...})
export class DataComponent {
  constructor() {
    this.dataService.data$.pipe(
      takeUntilDestroyed() // Auto-unsubscribes on destroy
    ).subscribe(data => this.handleData(data));
  }
}
```

### DestroyRef (Outside Constructor)
```typescript
private destroyRef = inject(DestroyRef);

loadData() {
  this.http.get('/api').pipe(
    takeUntilDestroyed(this.destroyRef)
  ).subscribe();
}
```

### Async Pipe (Template)
```html
<div *ngIf="data$ | async as data">{{ data.name }}</div>
```

## State Management Patterns

### Signal-Based State
```typescript
@Injectable({ providedIn: 'root' })
export class CartService {
  #items = signal<CartItem[]>([]);
  readonly items = this.#items.asReadonly();  // Signals don't use $ suffix
  readonly total = computed(() => 
    this.items().reduce((sum, i) => sum + i.price, 0)
  );

  addItem(item: CartItem) {
    this.items.update(items => [...items, item]);
  }
}
```

### BehaviorSubject Service
```typescript
@Injectable({ providedIn: 'root' })
export class UserStateService {
  private userSubject = new BehaviorSubject<User | null>(null);
  user$ = this.userSubject.asObservable();
  isLoggedIn$ = this.user$.pipe(map(u => u !== null));

  setUser(user: User) { this.userSubject.next(user); }
}
```

## Caching and Error Handling

### shareReplay for Caching
```typescript
private users$ = this.http.get<User[]>('/api/users').pipe(
  shareReplay({ bufferSize: 1, refCount: true })  // Cache and auto-cleanup
);
```

### Loading/Error State Pattern
```typescript
interface AsyncState<T> {
  data: T | null;
  loading: boolean;
  error: string | null;
}

// Signal version
private state = signal<AsyncState<User[]>>({ data: null, loading: false, error: null });
readonly users = computed(() => this.state().data);
readonly loading = computed(() => this.state().loading);
readonly error = computed(() => this.state().error);

loadUsers() {
  this.state.update(s => ({ ...s, loading: true, error: null }));
  this.http.get<User[]>('/api/users').subscribe({
    next: data => this.state.set({ data, loading: false, error: null }),
    error: err => this.state.update(s => ({ ...s, loading: false, error: err.message }))
  });
}
```

## Signals vs Observables

**Use Signals**: Synchronous state, computed values, template binding
**Use Observables**: HTTP, WebSocket, complex streams, need operators

```typescript
import { toSignal, toObservable } from '@angular/core/rxjs-interop';

// Observable to Signal
const users = toSignal(this.http.get<User[]>('/api/users'), { initialValue: [] });

// Signal to Observable
const term$ = toObservable(this.searchTerm);
const results$ = term$.pipe(debounceTime(300), switchMap(t => this.search(t)));
```

## NgRx (Signal Store + Classic Store)

NgRx is the canonical Redux-pattern state library for Angular. Modern NgRx (17+) ships a **Signal Store** that integrates with Angular signals — no RxJS required for component reads.

### Classic Store (Feature Modules)

Best for: large apps, cross-feature interactions, time-travel debugging, strict unidirectional data flow.

```typescript
// counter.actions.ts
import { createAction, props } from '@ngrx/store';
export const increment = createAction('[Counter] Increment');
export const set = createAction('[Counter] Set', props<{ value: number }>());

// counter.reducer.ts
import { createReducer, on } from '@ngrx/store';
export const counterReducer = createReducer(
  0,
  on(increment, (state) => state + 1),
  on(set, (_state, { value }) => value),
);

// counter.selectors.ts
import { createFeature, createSelector } from '@ngrx/store';
export const counterFeature = createFeature({ reducer: counterReducer });

// Component
@Component({...})
export class CounterComponent {
  private store = inject(Store);
  count = this.store.selectSignal(counterFeature.select.count);  // signal!
  inc() { this.store.dispatch(increment()); }
}
```

### Signal Store (NgRx 17+)

Best for: feature-scoped state, lighter boilerplate than the classic store, signal-native reads.

```typescript
import { signalStore, withState, withMethods, withComputed, patchState } from '@ngrx/signals';

type CartState = { items: CartItem[] };
const initialState: CartState = { items: [] };

export const CartStore = signalStore(
  { providedIn: 'root' },
  withState(initialState),
  withComputed(({ items }) => ({
    total: computed(() => items().reduce((s, i) => s + i.price, 0)),
    count: computed(() => items().length),
  })),
  withMethods((store) => ({
    add(item: CartItem) { patchState(store, (s) => ({ items: [...s.items, item] })); },
    remove(id: string) { patchState(store, (s) => ({ items: s.items.filter(i => i.id !== id) })); },
  })),
);

// Component
@Component({...})
export class CartComponent {
  cart = inject(CartStore);
  // cart.items(), cart.total(), cart.count() are all signals
}
```

### Choosing between the three

| Approach | When to pick |
|----------|--------------|
| `BehaviorSubject` service | Small app, single feature, no time-travel/devtools need |
| Signals (custom service) | Modern default for new features; no boilerplate |
| NgRx Signal Store | Multiple related entities, derived state, feature-scoped, no cross-feature coordination |
| NgRx Classic Store (`@ngrx/store`) | Large app, strict unidirectional flow, effects, time-travel, cross-feature coordination, established team patterns |

For new Angular v21+ projects, start with the signal service pattern (see "Signal-Based State" above) and reach for NgRx only when you outgrow it — usually when 3+ components need to read/write the same state, or when you need `@ngrx/effects` for side effects.

## Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| Cannot read property of undefined | Observable not emitted yet | Use async pipe or initialValue |
| ExpressionChangedAfterItHasBeenChecked | State mutated during CD | Schedule with `afterNextRender` or refactor |
| Memory leak | Subscription not cleaned | Use takeUntilDestroyed |
| No provider for DestroyRef | Outside injection context | Inject and pass DestroyRef |

## Context7 Integration

Fetch up-to-date documentation:
```
context7_resolve-library-id: "RxJS"
context7_query-docs: libraryId="/reactivex/rxjs" query="switchMap mergeMap"
```

## Related Skills

- `angular-components` - Component architecture and lifecycle
- `angular-testing` - Testing observables and signals
- `typescript-advanced` - Generics and type inference for RxJS

## References

| Reference | Description |
|-----------|-------------|
| [research.md](references/research.md) | Detailed patterns and operators |
| [Angular Signals](https://angular.dev/guide/signals) | Official signals docs |
| [RxJS Interop](https://angular.dev/ecosystem/rxjs-interop) | toSignal, takeUntilDestroyed |
