# Angular State Management & RxJS Research

## Overview

This document captures research findings on Angular state management patterns, RxJS best practices, and the integration of Angular signals with reactive programming.

---

## Observable Fundamentals

### Hot vs Cold Observables

**Cold Observables**
- Create a new execution for each subscriber
- Data is produced inside the Observable
- Examples: `of()`, `from()`, `interval()`, HTTP requests
- Each subscription triggers a new execution

```typescript
// Cold Observable - each subscriber gets own execution
const cold$ = new Observable(subscriber => {
  subscriber.next(Math.random()); // Different value per subscriber
});
```

**Hot Observables**
- Share a single execution among subscribers
- Data is produced outside the Observable
- Examples: Subjects, `fromEvent()`, `share()`/`shareReplay()`
- Late subscribers miss earlier emissions

```typescript
// Hot Observable - all subscribers share execution
const subject = new Subject<number>();
subject.next(1); // Emitted before subscriptions miss this
```

### When to Use Each
- **Cold**: HTTP requests, one-time data fetches, file reads
- **Hot**: User events, WebSocket connections, shared state

---

## Subject Types

### Subject
- No initial value, no replay
- Multicast to multiple observers
- Use when: Broadcasting events with no need for history

```typescript
const subject = new Subject<string>();
subject.subscribe(val => console.log('A:', val));
subject.next('hello'); // A: hello
subject.subscribe(val => console.log('B:', val));
subject.next('world'); // A: world, B: world
```

### BehaviorSubject
- Requires initial value
- Emits current value to new subscribers
- Use when: Components need immediate current state

```typescript
const behavior$ = new BehaviorSubject<number>(0);
behavior$.subscribe(val => console.log('Late sub:', val)); // Immediately: 0
behavior$.next(1);
behavior$.subscribe(val => console.log('Later sub:', val)); // Immediately: 1
```

### ReplaySubject
- Replays specified number of emissions to new subscribers
- Optional time window for replay
- Use when: Late subscribers need recent history

```typescript
const replay$ = new ReplaySubject<number>(2); // Buffer last 2
replay$.next(1);
replay$.next(2);
replay$.next(3);
replay$.subscribe(val => console.log(val)); // 2, 3 (last 2)
```

### AsyncSubject
- Only emits last value, and only on completion
- Use when: Only final result matters (rare)

```typescript
const async$ = new AsyncSubject<number>();
async$.next(1);
async$.next(2);
async$.complete();
async$.subscribe(val => console.log(val)); // 2 (only after complete)
```

---

## Essential RxJS Operators

### Transformation Operators (Flattening)

| Operator | Behavior | Use Case |
|----------|----------|----------|
| `switchMap` | Cancels previous, switches to new | Typeahead, autocomplete, route params |
| `mergeMap` | Maintains all subscriptions | Parallel requests, writes to DB |
| `concatMap` | Queues, processes in order | Sequential requests, ordered operations |
| `exhaustMap` | Ignores new until current completes | Prevent duplicate form submissions |

#### switchMap
```typescript
// Typeahead - cancel previous search on new input
searchInput$.pipe(
  debounceTime(300),
  switchMap(term => this.http.get(`/search?q=${term}`))
).subscribe(results => this.results = results);
```

#### mergeMap
```typescript
// Save all clicks - don't cancel any
clicks$.pipe(
  mergeMap(event => this.saveClick(event))
).subscribe();
```

#### concatMap
```typescript
// Process queue in order
queue$.pipe(
  concatMap(item => this.processItem(item))
).subscribe();
```

#### exhaustMap
```typescript
// Prevent double-submit on button spam
submitBtn$.pipe(
  exhaustMap(() => this.submitForm())
).subscribe();
```

### Combination Operators

#### combineLatest
- Emits when ANY source emits (after all have emitted once)
- Returns array of latest values from each

```typescript
combineLatest([
  this.user$,
  this.permissions$,
  this.settings$
]).subscribe(([user, permissions, settings]) => {
  // React to any change
});
```

#### forkJoin
- Waits for ALL to complete, emits final values
- Good for parallel HTTP requests

```typescript
forkJoin({
  user: this.http.get('/user'),
  posts: this.http.get('/posts')
}).subscribe(({ user, posts }) => {
  // Both complete
});
```

#### withLatestFrom
- Emits when source emits, includes latest from others
- Others don't trigger emissions

```typescript
save$.pipe(
  withLatestFrom(this.form.valueChanges)
).subscribe(([_, formValue]) => {
  this.saveForm(formValue);
});
```

### Filtering Operators

```typescript
// Common filtering patterns
source$.pipe(
  filter(val => val > 0),
  distinctUntilChanged(),
  debounceTime(300),
  take(5),
  takeUntil(this.destroy$)
);
```

---

## Memory Leak Prevention

### The Problem
Subscriptions that outlive their components cause memory leaks, continued execution, and potential errors.

### Solution 1: takeUntilDestroyed (Recommended for Angular)
```typescript
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';

@Component({...})
export class MyComponent {
  constructor() {
    this.data$.pipe(
      takeUntilDestroyed() // Auto-unsubscribes on destroy
    ).subscribe(data => this.handleData(data));
  }
}
```

### Solution 2: DestroyRef for Non-Constructor Usage
```typescript
@Component({...})
export class MyComponent {
  private destroyRef = inject(DestroyRef);

  ngOnInit() {
    this.data$.pipe(
      takeUntilDestroyed(this.destroyRef)
    ).subscribe();
  }
}
```

### Solution 3: Async Pipe (Template-based)
```typescript
// Component
data$ = this.service.getData();

// Template - auto subscribes/unsubscribes
<div>{{ data$ | async }}</div>
<div *ngIf="data$ | async as data">{{ data.name }}</div>
```

### Solution 4: Manual takeUntil Pattern (Legacy)
```typescript
@Component({...})
export class MyComponent implements OnDestroy {
  private destroy$ = new Subject<void>();

  ngOnInit() {
    this.data$.pipe(
      takeUntil(this.destroy$)
    ).subscribe();
  }

  ngOnDestroy() {
    this.destroy$.next();
    this.destroy$.complete();
  }
}
```

### Common Leak Scenarios
1. **Interval without unsubscription**
2. **Event listeners without cleanup**
3. **Route parameter subscriptions**
4. **WebSocket connections**
5. **Form value changes**

---

## State Management Approaches

### 1. Simple Service with BehaviorSubject

```typescript
@Injectable({ providedIn: 'root' })
export class UserStateService {
  private userSubject = new BehaviorSubject<User | null>(null);
  
  user$ = this.userSubject.asObservable();
  
  setUser(user: User) {
    this.userSubject.next(user);
  }
  
  get currentUser(): User | null {
    return this.userSubject.getValue();
  }
}
```

### 2. Signal-Based State (Modern Angular)

```typescript
@Injectable({ providedIn: 'root' })
export class UserStateService {
  private user = signal<User | null>(null);
  
  readonly user$ = this.user.asReadonly();
  readonly isLoggedIn = computed(() => this.user() !== null);
  
  setUser(user: User) {
    this.user.set(user);
  }
  
  updateUser(partial: Partial<User>) {
    this.user.update(current => current ? { ...current, ...partial } : null);
  }
}
```

### 3. NgRx Store (Complex Applications)

```typescript
// Actions
export const loadUsers = createAction('[Users] Load');
export const loadUsersSuccess = createAction(
  '[Users] Load Success',
  props<{ users: User[] }>()
);

// Reducer
export const usersReducer = createReducer(
  initialState,
  on(loadUsersSuccess, (state, { users }) => ({ ...state, users }))
);

// Effects
loadUsers$ = createEffect(() => this.actions$.pipe(
  ofType(loadUsers),
  exhaustMap(() => this.userService.getUsers().pipe(
    map(users => loadUsersSuccess({ users })),
    catchError(error => of(loadUsersFailure({ error })))
  ))
));
```

### When to Use Each

| Approach | Complexity | Use Case |
|----------|------------|----------|
| BehaviorSubject service | Simple | Small apps, single source of truth |
| Signals | Simple-Medium | Modern Angular, computed state |
| NgRx | Complex | Large apps, time-travel debugging, team conventions |

---

## Angular Signals

### Core Concepts

```typescript
// Writable signal
const count = signal(0);
count.set(5);
count.update(val => val + 1);

// Computed (derived state)
const doubled = computed(() => count() * 2);

// Effect (side effects)
effect(() => {
  console.log('Count changed:', count());
});
```

### Signals vs Observables

| Feature | Signals | Observables |
|---------|---------|-------------|
| Synchronous | Yes | Can be async |
| Always has value | Yes | No (must subscribe) |
| Push vs Pull | Pull (read when needed) | Push (values pushed) |
| Automatic cleanup | Yes (in components) | Need unsubscription |
| Complex streams | Limited | Full power |

### Signal-Observable Interop

```typescript
import { toSignal, toObservable } from '@angular/core/rxjs-interop';

// Observable to Signal
const data$ = this.http.get<Data>('/api/data');
const dataSignal = toSignal(data$, { initialValue: null });

// Signal to Observable
const count = signal(0);
const count$ = toObservable(count);
```

### When to Use Signals vs Observables

**Use Signals for:**
- Component-level state
- Simple derived/computed values
- Template bindings (cleaner than async pipe)
- Synchronous state updates

**Use Observables for:**
- Async operations (HTTP, WebSocket)
- Complex event streams
- Time-based operations
- When you need operators (debounce, retry, etc.)

---

## Error Handling in Streams

### catchError
```typescript
this.http.get('/api/data').pipe(
  catchError(error => {
    console.error('Request failed:', error);
    return of([]); // Return fallback value
  })
).subscribe(data => this.data = data);
```

### retry and retryWhen
```typescript
this.http.get('/api/data').pipe(
  retry(3), // Retry 3 times immediately
  catchError(error => of([]))
).subscribe();

// With delay
this.http.get('/api/data').pipe(
  retry({
    count: 3,
    delay: (error, retryCount) => timer(retryCount * 1000)
  })
).subscribe();
```

### Error Handling in Effects (NgRx)
```typescript
loadData$ = createEffect(() => this.actions$.pipe(
  ofType(loadData),
  exhaustMap(() => this.dataService.load().pipe(
    map(data => loadDataSuccess({ data })),
    catchError(error => of(loadDataFailure({ error })))
  ))
));
```

---

## Testing Observables

### Using fakeAsync and tick
```typescript
it('should debounce search', fakeAsync(() => {
  const results: string[] = [];
  
  component.search$.pipe(
    debounceTime(300)
  ).subscribe(val => results.push(val));
  
  component.searchInput.setValue('a');
  component.searchInput.setValue('ab');
  component.searchInput.setValue('abc');
  
  tick(300);
  
  expect(results).toEqual(['abc']); // Only final value after debounce
}));
```

### Using Marble Testing
```typescript
import { TestScheduler } from 'rxjs/testing';

const scheduler = new TestScheduler((actual, expected) => {
  expect(actual).toEqual(expected);
});

scheduler.run(({ cold, expectObservable }) => {
  const source$ = cold('a-b-c|');
  const expected = 'a-b-c|';
  
  expectObservable(source$).toBe(expected);
});
```

### Testing Services with Subjects
```typescript
describe('DataService', () => {
  let service: DataService;
  
  beforeEach(() => {
    TestBed.configureTestingModule({});
    service = TestBed.inject(DataService);
  });
  
  it('should emit updated values', (done) => {
    const expected = { id: 1, name: 'Test' };
    
    service.data$.subscribe(data => {
      expect(data).toEqual(expected);
      done();
    });
    
    service.setData(expected);
  });
});
```

---

## Common Patterns

### Caching with shareReplay
```typescript
@Injectable({ providedIn: 'root' })
export class ConfigService {
  private config$ = this.http.get<Config>('/api/config').pipe(
    shareReplay(1) // Cache and replay to late subscribers
  );
  
  getConfig(): Observable<Config> {
    return this.config$;
  }
}
```

### Polling
```typescript
const poll$ = timer(0, 5000).pipe(
  switchMap(() => this.http.get('/api/status')),
  takeUntilDestroyed()
);
```

### Optimistic Updates
```typescript
updateItem(item: Item) {
  // Update UI immediately
  this.items.update(items => 
    items.map(i => i.id === item.id ? item : i)
  );
  
  // Sync with server
  this.http.put(`/api/items/${item.id}`, item).pipe(
    catchError(error => {
      // Revert on failure
      this.items.update(items => 
        items.map(i => i.id === item.id ? originalItem : i)
      );
      return throwError(() => error);
    })
  ).subscribe();
}
```

---

## Resources

- [Angular Signals Documentation](https://angular.dev/guide/signals)
- [RxJS Interop](https://angular.dev/ecosystem/rxjs-interop)
- [Learn RxJS](https://www.learnrxjs.io/)
- [takeUntilDestroyed](https://angular.dev/ecosystem/rxjs-interop/take-until-destroyed)
