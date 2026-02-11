---
name: angular-testing
description: Write, create, generate, debug, and fix Angular unit tests, component tests, service tests, e2e tests with Vitest, Jest, Jasmine, TestBed, Cypress, and Playwright. Use when testing components, services, signals, observables, DOM interactions, or mocking dependencies.
license: MIT
metadata:
  version: 1.0.0
  audience: developers
  workflow: testing
---

# Angular Testing

## What I Do

- Write unit tests for Angular components, services, pipes, and directives
- Configure TestBed for component and service testing
- Create mocks, spies, and test doubles for dependencies
- Test signal-based components and computed values
- Handle async testing with fakeAsync, tick, and waitForAsync
- Test HTTP services with HttpTestingController
- Set up e2e tests with Cypress or Playwright
- Debug failing tests and fix test isolation issues

## When to Use Me

Use this skill when you:
- Write, create, or generate unit tests for Angular components
- Test services with dependencies or HTTP calls
- Debug failing or flaky Angular tests
- Configure TestBed or test module setup
- Mock services, spies, or providers in tests
- Test signal-based reactivity and computed signals
- Handle async operations in tests (Observables, Promises)
- Set up end-to-end testing with Cypress or Playwright

## Context7 Integration

For up-to-date Angular testing documentation:
```
context7_resolve-library-id("Angular", "Angular testing TestBed component service")
context7_query-docs("/angular/angular", "TestBed component testing fakeAsync")
```

## Component Testing

### Basic Component Test
```typescript
import { ComponentFixture, TestBed } from '@angular/core/testing';

describe('HeroComponent', () => {
  let component: HeroComponent;
  let fixture: ComponentFixture<HeroComponent>;

  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [HeroComponent]  // Standalone component
    });
    fixture = TestBed.createComponent(HeroComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should display hero name', () => {
    component.hero = { id: 1, name: 'Superman' };
    fixture.detectChanges();
    expect(fixture.nativeElement.querySelector('.hero-name').textContent)
      .toContain('Superman');
  });
});
```

### Testing Signal Components
```typescript
it('should update when signal changes', async () => {
  component.title.set('Updated Title');
  await fixture.whenStable();
  fixture.detectChanges();
  expect(fixture.nativeElement.querySelector('h1').textContent)
    .toContain('Updated Title');
});

// Set signal inputs
fixture.componentRef.setInput('heroId', 42);
await fixture.whenStable();
```

### OnPush Change Detection
```typescript
// OnPush components need explicit triggers
fixture.componentRef.setInput('name', 'New Name');
fixture.detectChanges();
```

## Service Testing

### Service with Dependencies
```typescript
let service: MasterService;
let valueServiceSpy: jasmine.SpyObj<ValueService>;

beforeEach(() => {
  const spy = jasmine.createSpyObj('ValueService', ['getValue']);
  TestBed.configureTestingModule({
    providers: [MasterService, { provide: ValueService, useValue: spy }]
  });
  service = TestBed.inject(MasterService);
  valueServiceSpy = TestBed.inject(ValueService) as jasmine.SpyObj<ValueService>;
});

it('should use injected service', () => {
  valueServiceSpy.getValue.and.returnValue('stubbed');
  expect(service.getValue()).toBe('stubbed');
});
```

### HTTP Service Testing
```typescript
import { provideHttpClient } from '@angular/common/http';
import { provideHttpClientTesting, HttpTestingController } from '@angular/common/http/testing';

beforeEach(() => {
  TestBed.configureTestingModule({
    providers: [HeroService, provideHttpClient(), provideHttpClientTesting()]
  });
  httpController = TestBed.inject(HttpTestingController);
});

afterEach(() => httpController.verify());

it('should fetch heroes', () => {
  service.getHeroes().subscribe(heroes => expect(heroes.length).toBe(2));
  const req = httpController.expectOne('api/heroes');
  req.flush([{ id: 1, name: 'A' }, { id: 2, name: 'B' }]);
});
```

## Async Testing

### fakeAsync and tick
```typescript
import { fakeAsync, tick, flush } from '@angular/core/testing';

it('should handle async', fakeAsync(() => {
  let value = '';
  setTimeout(() => value = 'done', 100);
  tick(100);
  expect(value).toBe('done');
}));

// For observables with delay
it('should handle delayed observable', fakeAsync(() => {
  let result: string;
  of('value').pipe(delay(1000)).subscribe(v => result = v);
  tick(1000);
  expect(result).toBe('value');
}));
```

### Async Helpers
```typescript
export function asyncData<T>(data: T): Observable<T> {
  return defer(() => Promise.resolve(data));
}

serviceSpy.getData.and.returnValue(asyncData({ name: 'Test' }));
```

## DOM Testing

```typescript
// Query elements
const button = fixture.nativeElement.querySelector('button');
const buttonDe = fixture.debugElement.query(By.css('button'));

// User interactions
button.click();
fixture.detectChanges();

// Input changes
const input: HTMLInputElement = fixture.nativeElement.querySelector('input');
input.value = 'new value';
input.dispatchEvent(new Event('input'));
fixture.detectChanges();

// Test outputs
component.selected.subscribe(hero => emitted = hero);
button.click();
expect(emitted).toEqual(expectedHero);
```

## E2E Testing

### Cypress
```typescript
describe('Heroes', () => {
  beforeEach(() => cy.visit('/heroes'));

  it('should display hero list', () => {
    cy.get('.hero-item').should('have.length.greaterThan', 0);
  });

  it('should navigate to detail', () => {
    cy.get('.hero-item').first().click();
    cy.url().should('match', /\/heroes\/\d+/);
  });
});
```

### Playwright
```typescript
test('should display hero list', async ({ page }) => {
  await page.goto('/heroes');
  await expect(page.locator('.hero-item')).toHaveCount(10);
});
```

## Router Testing

```typescript
import { provideRouter } from '@angular/router';
import { RouterTestingHarness } from '@angular/router/testing';

describe('UserComponent with routing', () => {
  let harness: RouterTestingHarness;

  beforeEach(async () => {
    TestBed.configureTestingModule({
      providers: [
        provideRouter([{ path: 'users/:id', component: UserComponent }])
      ]
    });
    harness = await RouterTestingHarness.create();
  });

  it('should load user from route param', async () => {
    const component = await harness.navigateByUrl('/users/123', UserComponent);
    expect(component.userId()).toBe('123');
  });
});
```

## Forms Testing

```typescript
it('should validate required field', () => {
  component.form.controls.name.setValue('');
  expect(component.form.controls.name.hasError('required')).toBeTrue();

  component.form.controls.name.setValue('John');
  expect(component.form.valid).toBeTrue();
});
```

## Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| "No provider for X" | Missing provider | Add to TestBed providers |
| "Cannot read property of undefined" | Missing detectChanges | Call `fixture.detectChanges()` |
| "timer(s) still in queue" | Unprocessed async | Use `flush()` or `tick()` |
| OnPush not updating | CD not triggered | Use `setInput()` + `detectChanges()` |
| "Changed after checked" | Value changed during CD | Use `autoDetectChanges()` |

## Best Practices

1. **Test behavior, not implementation** - Focus on user-visible outcomes
2. **Use data-testid attributes** - Avoid fragile CSS selectors
3. **Mock sparingly** - Only mock HTTP and complex external services
4. **Handle async properly** - Always use fakeAsync, waitForAsync, or done()
5. **Clean up** - Verify HTTP requests in afterEach
6. **Test error paths** - Don't just test happy paths

## Related Skills

- **angular-components** - Component architecture and patterns
- **angular-state** - State management with signals
- **typescript-advanced** - TypeScript patterns for tests
