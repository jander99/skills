# Angular Testing Research

## Overview

Angular testing has evolved significantly. As of Angular v21, **Vitest** is now the default testing framework for new CLI projects, replacing Karma/Jasmine. The framework uses `jsdom` for DOM emulation in Node.js.

## Testing Frameworks

### Vitest (Default for Angular v21+)
- Runs in Node.js environment with jsdom
- Faster execution (no browser launch overhead)
- Compatible with Jasmine-style syntax
- Configurable via `angular.json` test target options

### Jasmine/Karma (Legacy)
- Still supported but being phased out
- Runs tests in real browser
- Migration guide available: `guide/testing/migrating-to-vitest`

### Jest
- Popular alternative with similar API to Jasmine
- Requires additional setup with Angular
- Use `jest-preset-angular` for configuration

## TestBed Configuration

### Basic Setup
```typescript
import { ComponentFixture, TestBed } from '@angular/core/testing';

describe('MyComponent', () => {
  let component: MyComponent;
  let fixture: ComponentFixture<MyComponent>;

  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [MyComponent], // standalone components
      // declarations: [MyComponent], // NgModule-based
      providers: [
        { provide: MyService, useValue: mockService }
      ]
    });

    fixture = TestBed.createComponent(MyComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });
});
```

### Global Test Providers
Create `src/test-providers.ts`:
```typescript
import { Provider } from '@angular/core';
import { provideHttpClient } from '@angular/common/http';
import { provideHttpClientTesting } from '@angular/common/http/testing';

const testProviders: Provider[] = [
  provideHttpClient(),
  provideHttpClientTesting()
];

export default testProviders;
```

Reference in `angular.json`:
```json
{
  "test": {
    "options": {
      "providersFile": "src/test-providers.ts"
    }
  }
}
```

## Component Testing

### ComponentFixture API
```typescript
const fixture = TestBed.createComponent(BannerComponent);

// Access component instance
const component = fixture.componentInstance;

// Access native element
const element: HTMLElement = fixture.nativeElement;

// Access DebugElement (platform-agnostic)
const debugEl: DebugElement = fixture.debugElement;

// Trigger change detection
fixture.detectChanges();

// Wait for async operations
await fixture.whenStable();
```

### DOM Querying
```typescript
// querySelector approach
const p = fixture.nativeElement.querySelector('p');

// DebugElement with By.css (platform-agnostic)
import { By } from '@angular/platform-browser';
const paragraphDe = fixture.debugElement.query(By.css('p'));
const p: HTMLElement = paragraphDe.nativeElement;

// Query by directive
const linkDes = fixture.debugElement.queryAll(By.directive(RouterLink));
```

### Automatic Change Detection
```typescript
import { ComponentFixtureAutoDetect } from '@angular/core/testing';

TestBed.configureTestingModule({
  providers: [
    { provide: ComponentFixtureAutoDetect, useValue: true }
  ]
});

// Or per-fixture
fixture.autoDetectChanges();
```

### Setting Inputs (Angular 16+)
```typescript
// For signal inputs
fixture.componentRef.setInput('hero', expectedHero);

// Wait for binding
await fixture.whenStable();
```

## Service Testing

### Without TestBed (Simple Services)
```typescript
describe('ValueService', () => {
  let service: ValueService;

  beforeEach(() => {
    service = new ValueService();
  });

  it('should return value', () => {
    expect(service.getValue()).toBe('real value');
  });
});
```

### With TestBed (Services with Dependencies)
```typescript
let service: MasterService;
let valueServiceSpy: jasmine.SpyObj<ValueService>;

beforeEach(() => {
  const spy = jasmine.createSpyObj('ValueService', ['getValue']);

  TestBed.configureTestingModule({
    providers: [
      MasterService,
      { provide: ValueService, useValue: spy }
    ]
  });

  service = TestBed.inject(MasterService);
  valueServiceSpy = TestBed.inject(ValueService) as jasmine.SpyObj<ValueService>;
});
```

### HTTP Service Testing
```typescript
import { provideHttpClient } from '@angular/common/http';
import { provideHttpClientTesting, HttpTestingController } from '@angular/common/http/testing';

beforeEach(() => {
  TestBed.configureTestingModule({
    providers: [
      HeroService,
      provideHttpClient(),
      provideHttpClientTesting()
    ]
  });

  httpController = TestBed.inject(HttpTestingController);
  service = TestBed.inject(HeroService);
});

it('should fetch heroes', () => {
  service.getHeroes().subscribe(heroes => {
    expect(heroes.length).toBe(2);
  });

  const req = httpController.expectOne('api/heroes');
  expect(req.request.method).toBe('GET');
  req.flush([{ id: 1, name: 'A' }, { id: 2, name: 'B' }]);
});

afterEach(() => {
  httpController.verify();
});
```

## Testing Signals

### Signal Components
```typescript
@Component({
  template: '<h1>{{title()}}</h1>'
})
export class BannerComponent {
  title = signal('Test Tour of Heroes');
}

// Test
it('should display title', () => {
  fixture.detectChanges();
  expect(fixture.nativeElement.querySelector('h1').textContent)
    .toContain('Test Tour of Heroes');
});

it('should update when signal changes', async () => {
  component.title.set('New Title');
  await fixture.whenStable();
  fixture.detectChanges();
  expect(fixture.nativeElement.querySelector('h1').textContent)
    .toContain('New Title');
});
```

### Computed Signals
```typescript
@Component({...})
export class CounterComponent {
  count = signal(0);
  doubleCount = computed(() => this.count() * 2);
}

it('should compute derived value', () => {
  component.count.set(5);
  expect(component.doubleCount()).toBe(10);
});
```

### Testing with Effects
Effects run asynchronously, use `fakeAsync` or `waitForAsync`:
```typescript
it('should trigger effect', fakeAsync(() => {
  component.trigger.set(true);
  tick();
  expect(component.effectResult).toBe('triggered');
}));
```

## OnPush Change Detection

### Challenge
OnPush components only update when:
- Input references change
- Event handlers fire
- Async pipe emits
- `markForCheck()` is called

### Testing Strategy
```typescript
@Component({
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: '<span>{{name()}}</span>'
})
export class OnPushComponent {
  name = input<string>();
}

it('should update with input change', async () => {
  fixture.componentRef.setInput('name', 'Initial');
  fixture.detectChanges();

  fixture.componentRef.setInput('name', 'Updated');
  fixture.detectChanges();

  expect(fixture.nativeElement.textContent).toContain('Updated');
});
```

### Using ChangeDetectorRef in Tests
```typescript
import { ChangeDetectorRef } from '@angular/core';

it('should update with markForCheck', () => {
  const cdr = fixture.debugElement.injector.get(ChangeDetectorRef);
  component.data = 'new value';
  cdr.markForCheck();
  fixture.detectChanges();
  expect(fixture.nativeElement.textContent).toContain('new value');
});
```

## Async Testing Patterns

### fakeAsync/tick
```typescript
import { fakeAsync, tick } from '@angular/core/testing';

it('should handle async', fakeAsync(() => {
  let result = '';
  setTimeout(() => result = 'done', 100);

  tick(100);
  expect(result).toBe('done');
}));
```

### waitForAsync
```typescript
import { waitForAsync } from '@angular/core/testing';

it('should handle promise', waitForAsync(() => {
  service.getData().then(data => {
    expect(data).toBeDefined();
  });
}));
```

### Testing Observables
```typescript
it('should emit values', (done: DoneFn) => {
  service.getObservable().subscribe({
    next: value => {
      expect(value).toBe('expected');
      done();
    },
    error: done.fail
  });
});

// With fakeAsync
it('should handle delayed observable', fakeAsync(() => {
  let result: string;
  service.getDelayedData().subscribe(v => result = v);
  tick(1000);
  expect(result).toBe('delayed value');
}));
```

### Async Observable Helpers
```typescript
// Create async data helper
export function asyncData<T>(data: T) {
  return defer(() => Promise.resolve(data));
}

// Create async error helper
export function asyncError<T>(error: any) {
  return defer(() => Promise.reject(error));
}

// Usage
getQuoteSpy.and.returnValue(asyncData('test quote'));
```

## Mocking and Spies

### Jasmine Spies
```typescript
// Spy on method
const spy = spyOn(service, 'getValue').and.returnValue('mocked');

// Create spy object
const mockService = jasmine.createSpyObj('MyService', ['method1', 'method2']);
mockService.method1.and.returnValue('value');
```

### Jest Mocks
```typescript
// Mock function
const mockFn = jest.fn().mockReturnValue('mocked');

// Mock module
jest.mock('./my-service');

// Spy on method
jest.spyOn(service, 'method').mockReturnValue('value');
```

### Provider Mocking
```typescript
TestBed.configureTestingModule({
  providers: [
    { provide: MyService, useValue: mockService },
    { provide: MyService, useClass: MockMyService },
    { provide: MyService, useFactory: () => new MockMyService() }
  ]
});
```

## DOM Testing Patterns

### User Interactions
```typescript
// Click
element.click();

// Or via DebugElement
debugEl.triggerEventHandler('click', { button: 0 });

// Input change
const input: HTMLInputElement = fixture.nativeElement.querySelector('input');
input.value = 'new value';
input.dispatchEvent(new Event('input'));
fixture.detectChanges();
```

### Form Testing
```typescript
// Template-driven forms
const input = fixture.nativeElement.querySelector('input');
input.value = 'test';
input.dispatchEvent(new Event('input'));
await fixture.whenStable();

// Reactive forms
component.form.get('name')?.setValue('test');
fixture.detectChanges();
```

### Click Helper
```typescript
export function click(el: DebugElement | HTMLElement, eventObj: any = { button: 0 }): void {
  if (el instanceof HTMLElement) {
    el.click();
  } else {
    el.triggerEventHandler('click', eventObj);
  }
}
```

## Component Override Patterns

### Override Providers
```typescript
TestBed.overrideComponent(MyComponent, {
  set: {
    providers: [
      { provide: MyService, useClass: MockMyService }
    ]
  }
});
```

### Override Template
```typescript
TestBed.overrideComponent(MyComponent, {
  set: { template: '<div>mock template</div>' }
});
```

### Shallow Testing with NO_ERRORS_SCHEMA
```typescript
TestBed.configureTestingModule({
  imports: [MyComponent],
  schemas: [NO_ERRORS_SCHEMA]
});
```

### Stub Components
```typescript
@Component({ selector: 'app-child', template: '' })
class ChildStubComponent {}

TestBed.overrideComponent(ParentComponent, {
  set: { imports: [ChildStubComponent] }
});
```

## Test Isolation and Cleanup

### beforeEach/afterEach
```typescript
describe('MyComponent', () => {
  beforeEach(() => {
    // Setup
  });

  afterEach(() => {
    // Cleanup
    httpController.verify();
  });
});
```

### TestBed Reset
TestBed is automatically reset between test files. Within a file, each `beforeEach` reconfigures it.

### Avoiding Test Pollution
- Reset shared state in `beforeEach`
- Unsubscribe from observables
- Clear timers
- Restore spies

## E2E Testing

### Playwright Setup
```bash
npm install --save-dev @vitest/browser-playwright playwright
```

Run in browser:
```bash
ng test --browsers=chromium
```

### Cypress Setup
```bash
ng add @cypress/schematic
npx cypress open
```

### Cypress Example
```typescript
describe('Hero List', () => {
  beforeEach(() => {
    cy.visit('/heroes');
  });

  it('should display heroes', () => {
    cy.get('.hero-list-item').should('have.length.greaterThan', 0);
  });

  it('should navigate to detail', () => {
    cy.get('.hero-list-item').first().click();
    cy.url().should('include', '/heroes/');
  });
});
```

### Playwright Example
```typescript
import { test, expect } from '@playwright/test';

test.describe('Hero List', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/heroes');
  });

  test('should display heroes', async ({ page }) => {
    const heroes = page.locator('.hero-list-item');
    await expect(heroes).toHaveCount(10);
  });

  test('should navigate to detail', async ({ page }) => {
    await page.locator('.hero-list-item').first().click();
    await expect(page).toHaveURL(/\/heroes\/\d+/);
  });
});
```

## Routing Testing

### RouterTestingHarness
```typescript
import { RouterTestingHarness } from '@angular/router/testing';
import { provideRouter } from '@angular/router';

beforeEach(() => {
  TestBed.configureTestingModule({
    providers: [
      provideRouter([
        { path: 'heroes/:id', component: HeroDetailComponent }
      ])
    ]
  });
});

it('should navigate', async () => {
  const harness = await RouterTestingHarness.create();
  const component = await harness.navigateByUrl('/heroes/1', HeroDetailComponent);
  expect(component).toBeDefined();
});
```

## Common Anti-Patterns

### 1. Testing Implementation Details
**Bad:**
```typescript
it('should call private method', () => {
  expect((component as any).privateMethod()).toBe(true);
});
```
**Good:**
```typescript
it('should update display when triggered', () => {
  component.triggerAction();
  expect(fixture.nativeElement.textContent).toContain('Updated');
});
```

### 2. Overusing Mocks
Mock only what's necessary. Real implementations often catch more bugs.

### 3. Ignoring Async
Always handle async properly with `fakeAsync`, `waitForAsync`, or `done`.

### 4. Not Cleaning Up
Always verify HTTP requests, unsubscribe observables, clear intervals.

### 5. Testing Angular Instead of Your Code
Focus on your component's behavior, not Angular's internal workings.

### 6. Fragile Selectors
**Bad:**
```typescript
fixture.nativeElement.querySelector('div > span:nth-child(2)')
```
**Good:**
```typescript
fixture.nativeElement.querySelector('[data-testid="hero-name"]')
```

### 7. Ignoring Error Cases
Always test error handling paths.

## Page Object Pattern

```typescript
class HeroDetailPage {
  constructor(private harness: RouterTestingHarness) {}

  get nameInput() {
    return this.query<HTMLInputElement>('input#name');
  }

  get saveButton() {
    return this.query<HTMLButtonElement>('button.save');
  }

  async setName(name: string) {
    this.nameInput.value = name;
    this.nameInput.dispatchEvent(new Event('input'));
    await this.harness.fixture.whenStable();
  }

  private query<T>(selector: string): T {
    return this.harness.routeNativeElement!.querySelector(selector) as T;
  }
}
```

## Code Coverage

```bash
ng test --coverage
```

Coverage reports generated in `coverage/` directory.

Configure thresholds in `angular.json` or vitest config.

## Browser Testing (Vitest)

### Playwright Provider
```bash
npm install --save-dev @vitest/browser-playwright playwright
ng test --browsers=chromium
```

### WebdriverIO Provider
```bash
npm install --save-dev @vitest/browser-webdriverio webdriverio
ng test --browsers=chrome
```

### Headless Mode
```bash
ng test --browsers=chromiumHeadless
```

## CI/CD Integration

```bash
# Standard CI command
ng test --no-watch --no-progress

# With coverage
ng test --no-watch --coverage
```

Most CI servers set `CI=true` which Angular detects automatically.
