---
name: angular-components
description: Create, build, refactor, and optimize Angular components with signals, inputs, outputs, lifecycle hooks, change detection, content projection, and smart/presentational patterns. Use when building UI components, fixing component bugs, or improving performance.
license: MIT
metadata:
  version: 1.0.0
  audience: developers
  workflow: frontend-development
---

# Angular Components

## What I Do

- Create Angular components following modern best practices
- Implement signal-based inputs, outputs, and model bindings
- Configure change detection strategies (Default vs OnPush)
- Set up content projection with `ng-content`
- Apply smart/presentational component architecture
- Use lifecycle hooks correctly (ngOnInit, ngOnDestroy, afterRender)
- Query child components with viewChild/contentChild signals
- Fix common errors (ExpressionChangedAfterItHasBeenChecked)

## When to Use Me

Use this skill when you:
- Create, generate, or scaffold new Angular components
- Refactor components to use signals and modern APIs
- Implement parent-child component communication
- Configure content projection with ng-content slots
- Optimize components with OnPush change detection
- Debug lifecycle hook or change detection issues

## Component Architecture

### Smart vs Presentational Pattern

**Presentational** - Pure UI, no services, OnPush, input/output only:
```typescript
@Component({
  selector: 'user-card',
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `<div class="card"><h3>{{ name() }}</h3></div>`
})
export class UserCardComponent {
  readonly name = input.required<string>();
  readonly select = output<string>();
}
```

**Smart** - Inject services, manage state, coordinate children:
```typescript
@Component({
  selector: 'user-list-page',
  template: `@for (user of users(); track user.id) { <user-card [name]="user.name" /> }`
})
export class UserListPageComponent {
  private userService = inject(UserService);
  users = signal<User[]>([]);
}
```

## Inputs and Outputs

```typescript
// Signal inputs (recommended)
value = input(0);                                    // With default
userId = input.required<string>();                   // Required
label = input('', { transform: trimString });        // With transform
disabled = input(false, { transform: booleanAttribute }); // Built-in

// Model input (two-way binding)
value = model(0);  // Enables [(value)]="parentValue"

// Signal outputs
saved = output<void>();
valueChanged = output<number>();
this.valueChanged.emit(42);
```

## Lifecycle Hooks

**Order**: constructor → ngOnChanges → ngOnInit → ngAfterContentInit → ngAfterViewInit

```typescript
export class MyComponent implements OnInit {
  private destroyRef = inject(DestroyRef);

  ngOnInit() { this.loadData(); }

  constructor() {
    this.destroyRef.onDestroy(() => this.cleanup());
    afterNextRender(() => this.measureElement()); // DOM operations
  }
}
```

## Change Detection

**OnPush** triggers only when: input reference changes, event occurs, signal changes, or `markForCheck()` called.

```typescript
@Component({
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class OptimizedComponent {
  data = signal<Data | null>(null);
  displayName = computed(() => this.data()?.name ?? 'Unknown');
}
```

## Content Projection

```typescript
@Component({
  selector: 'card',
  template: `
    <ng-content select="[card-header]" />
    <ng-content select="[card-body]" />
    <ng-content>Fallback content</ng-content>
  `
})
export class CardComponent {}
```

## Component Queries

```typescript
// View queries (template elements)
header = viewChild(HeaderComponent);
header = viewChild.required(HeaderComponent);  // Guaranteed
items = viewChildren(ItemComponent);

// Content queries (projected content)
toggle = contentChild(ToggleComponent);
items = contentChildren(ItemComponent, { descendants: true });
```

## Context7 Integration

For current Angular documentation, use Context7 MCP server:
```
context7_resolve-library-id: angular
context7_query-docs: libraryId: /angular/angular, query: "signal inputs"
```

## Common Errors

**ExpressionChangedAfterItHasBeenChecked** - Schedule state changes:
```typescript
// BAD: Mutating bound state during change detection
ngAfterViewInit() { this.title = 'Changed'; }

// GOOD: Schedule for next tick
constructor() {
  afterNextRender(() => this.title.set('Changed'));
}
// Or refactor to compute value earlier (constructor/initializer)
```

**OnPush not updating** - Create new references:
```typescript
this.items = [...this.items, newItem]; // Not this.items.push()
```

**Memory leaks** - Use takeUntilDestroyed or toSignal:
```typescript
data = toSignal(this.data$);
// Or: this.data$.pipe(takeUntilDestroyed(this.destroyRef)).subscribe();
```

## Best Practices

1. Use signals for component state
2. Use OnPush for presentational components
3. Use computed instead of getters
4. Use inject() over constructor injection
5. Use readonly for inputs, outputs, queries
6. Track items in @for with unique IDs

## Reactive Forms Integration

```typescript
@Component({
  template: `<input [formControl]="nameControl">`
})
export class FormComponent {
  nameControl = new FormControl('', Validators.required);

  // Signal from form control value
  name = toSignal(this.nameControl.valueChanges, { initialValue: '' });
}
```

## Router Integration

```typescript
@Component({...})
export class UserComponent {
  private route = inject(ActivatedRoute);

  // Signal input from route (Angular 18+)
  userId = input.required<string>();  // With withComponentInputBinding()

  // Or from ActivatedRoute
  userId = toSignal(this.route.paramMap.pipe(
    map(params => params.get('id'))
  ));
}
```

## Related Skills

| Skill | Use When |
|-------|----------|
| [angular-state](../angular-state/) | Application state, stores, RxJS |
| [angular-testing](../angular-testing/) | Testing components, mocking |
| [typescript-advanced](../typescript-advanced/) | Generic components |
| [nx-workspace](../nx-workspace/) | Monorepo organization |

## References

| Reference | Description |
|-----------|-------------|
| [research.md](references/research.md) | Detailed patterns and examples |
| [Angular Docs](https://angular.dev/guide/components) | Official documentation |
