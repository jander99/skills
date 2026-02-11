# Angular Component Architecture Research

This document captures research findings on Angular component best practices, patterns, and modern APIs.

## Smart vs Presentational Components

### Presentational (Dumb) Components
- Focus purely on UI rendering
- Receive data via `input()` signals
- Emit events via `output()` functions
- No direct service injection for data fetching
- Highly reusable and testable
- Use `OnPush` change detection

```typescript
@Component({
  selector: 'user-card',
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <div class="card">
      <h3>{{ name() }}</h3>
      <button (click)="select.emit(id())">Select</button>
    </div>
  `
})
export class UserCardComponent {
  readonly id = input.required<string>();
  readonly name = input.required<string>();
  readonly select = output<string>();
}
```

### Smart (Container) Components
- Manage state and data fetching
- Inject services for business logic
- Coordinate child presentational components
- Handle routing and navigation logic
- May use Default change detection

```typescript
@Component({
  selector: 'user-list-page',
  template: `
    @for (user of users(); track user.id) {
      <user-card 
        [id]="user.id" 
        [name]="user.name"
        (select)="onUserSelect($event)" />
    }
  `
})
export class UserListPageComponent {
  private userService = inject(UserService);
  users = signal<User[]>([]);
  
  constructor() {
    this.loadUsers();
  }
  
  private async loadUsers() {
    this.users.set(await this.userService.getUsers());
  }
  
  onUserSelect(userId: string) {
    this.router.navigate(['/users', userId]);
  }
}
```

---

## Input/Output Patterns

### Signal-Based Inputs (Recommended)

```typescript
// Basic input with default
value = input(0);

// Required input
userId = input.required<string>();

// Input with transform
label = input('', { transform: trimString });

// Input with alias
internalValue = input(0, { alias: 'value' });
```

### Reading Input Values
Inputs are signals - call them to read:

```typescript
// In component class
label = computed(() => `Value: ${this.value()}`);

// In template
<span>{{ value() }}</span>
```

### Model Inputs (Two-Way Binding)
For components that need to write back to parent:

```typescript
@Component({
  selector: 'custom-slider',
})
export class CustomSlider {
  // Creates both input and automatic "valueChange" output
  value = model(0);
  
  increment() {
    this.value.update(v => v + 1); // Propagates to parent
  }
}

// Usage with two-way binding
<custom-slider [(value)]="volume" />
```

### Signal-Based Outputs (Recommended)

```typescript
// Basic output
saved = output<void>();

// Output with payload
valueChanged = output<number>();

// Output with alias
changed = output({ alias: 'valueChanged' });

// Emitting
this.saved.emit();
this.valueChanged.emit(42);
```

### Built-in Transforms

```typescript
import { booleanAttribute, numberAttribute } from '@angular/core';

// Boolean attribute (presence = true)
disabled = input(false, { transform: booleanAttribute });

// Number attribute
count = input(0, { transform: numberAttribute });
```

---

## Lifecycle Hooks

### Execution Order (Initialization)
1. `constructor` - Class instantiation
2. `ngOnChanges` - First input values
3. `ngOnInit` - Component initialization
4. `ngDoCheck` - Custom change detection
5. `ngAfterContentInit` - Content children ready
6. `ngAfterContentChecked` - Content checked
7. `ngAfterViewInit` - View children ready
8. `ngAfterViewChecked` - View checked

### Key Lifecycle Methods

#### ngOnInit
- Runs once after inputs initialized
- Best for initialization logic
- Template not yet rendered

```typescript
ngOnInit() {
  this.startDataFetch();
}
```

#### ngOnChanges
- Runs before ngOnInit and on every input change
- Receives `SimpleChanges` object

```typescript
ngOnChanges(changes: SimpleChanges<UserProfile>) {
  if (changes.userId) {
    console.log('Previous:', changes.userId.previousValue);
    console.log('Current:', changes.userId.currentValue);
    console.log('First:', changes.userId.firstChange);
  }
}
```

#### ngOnDestroy / DestroyRef
- Cleanup subscriptions, timers, listeners

```typescript
// Modern approach with DestroyRef
constructor() {
  inject(DestroyRef).onDestroy(() => {
    this.cleanup();
  });
}

// Traditional approach
ngOnDestroy() {
  this.subscription.unsubscribe();
}
```

#### afterNextRender / afterEveryRender
- For DOM operations after rendering
- Use phases for read/write separation

```typescript
constructor() {
  afterNextRender({
    write: () => {
      this.element.style.padding = '10px';
      return true; // Pass data to read phase
    },
    read: (didWrite) => {
      if (didWrite) {
        this.height = this.element.getBoundingClientRect().height;
      }
    }
  });
}
```

---

## Change Detection Strategies

### Default Strategy
- Checks entire component tree on every change
- Simple but can be slow for large apps

### OnPush Strategy
Checks component only when:
1. Input reference changes (using `===`)
2. Event originates in component or children
3. Async pipe emits
4. `markForCheck()` called manually
5. Signal value changes (in template)

```typescript
@Component({
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class OptimizedComponent {
  // Use signals - automatically trigger change detection
  data = signal<Data | null>(null);
  
  // Use computed for derived state
  displayName = computed(() => this.data()?.name ?? 'Unknown');
}
```

### Manual Change Detection

```typescript
private cdr = inject(ChangeDetectorRef);

// Mark for check (schedules check)
this.cdr.markForCheck();

// Detach from change detection
this.cdr.detach();

// Reattach
this.cdr.reattach();

// Run detection immediately
this.cdr.detectChanges();
```

---

## Content Projection

### Single Slot

```typescript
@Component({
  selector: 'card',
  template: `
    <div class="card">
      <ng-content />
    </div>
  `
})
export class CardComponent {}

// Usage
<card>
  <p>This content is projected</p>
</card>
```

### Multi-Slot with Selectors

```typescript
@Component({
  selector: 'card',
  template: `
    <div class="card">
      <ng-content select="[card-header]" />
      <ng-content select="[card-body]" />
      <ng-content /> <!-- Default slot -->
    </div>
  `
})
export class CardComponent {}

// Usage
<card>
  <h2 card-header>Title</h2>
  <p card-body>Body content</p>
  <span>Footer (default slot)</span>
</card>
```

### Fallback Content

```typescript
template: `
  <ng-content select="[header]">Default Header</ng-content>
`
```

### ngProjectAs Alias

```typescript
// Project as different selector
<card>
  <h3 ngProjectAs="[card-header]">Title</h3>
</card>
```

---

## Component Queries

### View Queries (Template Elements)

```typescript
// Single element
header = viewChild(HeaderComponent);
headerEl = viewChild<ElementRef>('headerRef');

// Required (guaranteed present)
header = viewChild.required(HeaderComponent);

// Multiple elements
items = viewChildren(ItemComponent);
```

### Content Queries (Projected Content)

```typescript
// Single projected element
toggle = contentChild(ToggleComponent);

// Multiple projected elements
menuItems = contentChildren(MenuItemComponent);

// With descendants (default false for contentChildren)
allItems = contentChildren(ItemComponent, { descendants: true });
```

### Reading Different Values

```typescript
// Get TemplateRef instead of directive
template = contentChild(MyDirective, { read: TemplateRef });

// Get ElementRef
element = viewChild('myRef', { read: ElementRef });
```

---

## Signals

### Creating Signals

```typescript
// Writable signal
count = signal(0);

// Reading
console.log(this.count());

// Writing
this.count.set(5);
this.count.update(v => v + 1);
```

### Computed Signals

```typescript
firstName = signal('John');
lastName = signal('Doe');

// Lazily evaluated, cached
fullName = computed(() => `${this.firstName()} ${this.lastName()}`);
```

### Effects

```typescript
constructor() {
  // Runs when dependencies change
  effect(() => {
    console.log('User changed:', this.currentUser());
  });
  
  // Untracked reads
  effect(() => {
    const user = this.currentUser();
    untracked(() => {
      this.logger.log(user); // Logger reads not tracked
    });
  });
}
```

### LinkedSignal (Dependent Writable State)

```typescript
// Writable signal that resets when source changes
selectedOption = linkedSignal(() => this.options()[0]);
```

### Resource (Async Data)

```typescript
// Async data as signal
userData = resource({
  request: () => this.userId(),
  loader: ({ request: userId }) => this.userService.getUser(userId)
});

// Access
this.userData.value();  // Data or undefined
this.userData.status(); // 'loading' | 'loaded' | 'error'
```

---

## Component Communication Patterns

### Parent to Child (Inputs)

```typescript
// Parent
<child-component [data]="parentData" />

// Child
data = input<Data>();
```

### Child to Parent (Outputs)

```typescript
// Child
saved = output<Data>();
this.saved.emit(data);

// Parent
<child-component (saved)="handleSave($event)" />
```

### Two-Way Binding (Model)

```typescript
// Child
value = model(0);

// Parent
<child-component [(value)]="parentValue" />
```

### Via Service (Shared State)

```typescript
@Injectable({ providedIn: 'root' })
export class StateService {
  private state = signal<AppState>(initialState);
  
  readonly state$ = this.state.asReadonly();
  
  updateState(partial: Partial<AppState>) {
    this.state.update(s => ({ ...s, ...partial }));
  }
}
```

### Via Queries (Direct Access)

```typescript
// Parent accessing child
childComponent = viewChild(ChildComponent);

doSomething() {
  this.childComponent()?.someMethod();
}
```

---

## Common Anti-Patterns

### Mutating Input Objects
```typescript
// BAD - Mutating input breaks OnPush
ngOnInit() {
  this.items().push(newItem); // Won't trigger change detection
}

// GOOD - Create new reference
addItem(item: Item) {
  this.items.update(items => [...items, item]);
}
```

### Heavy Logic in Templates
```typescript
// BAD - Recalculates every check
<div>{{ complexCalculation(data) }}</div>

// GOOD - Use computed
result = computed(() => this.complexCalculation(this.data()));
<div>{{ result() }}</div>
```

### Subscribing Without Cleanup
```typescript
// BAD - Memory leak
ngOnInit() {
  this.data$.subscribe(d => this.data = d);
}

// GOOD - Use takeUntilDestroyed
private destroyRef = inject(DestroyRef);

ngOnInit() {
  this.data$.pipe(
    takeUntilDestroyed(this.destroyRef)
  ).subscribe(d => this.data = d);
}

// BEST - Use signals/async pipe
data = toSignal(this.data$);
```

### Modifying State in Lifecycle Hooks

```typescript
// BAD - Causes ExpressionChangedAfterItHasBeenChecked
ngAfterViewInit() {
  this.title = 'New Title'; // Error in dev mode
}

// GOOD - Schedule for next cycle
ngAfterViewInit() {
  setTimeout(() => this.title = 'New Title');
  // Or use signals which handle this automatically
}
```

### Overusing ViewChild for Communication

```typescript
// BAD - Tight coupling
@ViewChild(ChildComponent) child: ChildComponent;

doThing() {
  this.child.internalMethod(); // Accessing internals
}

// GOOD - Use inputs/outputs
<child-component [config]="config" (result)="handleResult($event)" />
```

---

## Style Guide Recommendations

### File Naming
- Use hyphens: `user-profile.component.ts`
- Match class name: `UserProfileComponent`
- Test files: `user-profile.component.spec.ts`
- Same base name for template/styles: `user-profile.html`, `user-profile.css`

### Class Structure Order
1. Injected dependencies
2. Inputs
3. Outputs  
4. Queries (viewChild, contentChild)
5. Other properties
6. Constructor
7. Lifecycle methods
8. Public methods
9. Protected methods (for template)
10. Private methods

### Access Modifiers

```typescript
@Component({...})
export class UserProfile {
  // Public API via DI/queries
  readonly userId = input.required<string>();
  
  // Template-only (use protected)
  protected fullName = computed(() => ...);
  
  // Internal only
  private cache = new Map();
}
```

### Readonly for Angular Properties

```typescript
readonly userId = input.required<string>();
readonly saved = output<void>();
readonly childRef = viewChild(ChildComponent);
```

---

## Performance Best Practices

1. **Use OnPush** - Default for all presentational components
2. **Use Signals** - Automatic fine-grained reactivity
3. **Use trackBy with @for** - Efficient list rendering
4. **Lazy Load Routes** - Reduce initial bundle
5. **Use Computed** - Memoized derived state
6. **Avoid Complex Template Expressions** - Move to computed
7. **Use afterRender Phases** - Prevent layout thrashing

```typescript
@Component({
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    @for (item of items(); track item.id) {
      <item-card [item]="item" />
    }
  `
})
export class ItemListComponent {
  items = input.required<Item[]>();
  
  // Derived state is memoized
  activeItems = computed(() => 
    this.items().filter(i => i.active)
  );
}
```

---

## Sources
- https://angular.dev/guide/components
- https://angular.dev/guide/signals
- https://angular.dev/guide/components/lifecycle
- https://angular.dev/guide/components/inputs
- https://angular.dev/guide/components/outputs
- https://angular.dev/guide/components/content-projection
- https://angular.dev/guide/components/queries
- https://angular.dev/best-practices/skipping-subtrees
- https://angular.dev/style-guide
