# SOLID Principles - Complete Guide

## Overview

SOLID is a set of 5 design principles for writing maintainable, flexible object-oriented code.

---

## S - Single Responsibility Principle

**Definition**: A class should have one, and only one, reason to change

### ❌ Bad Example
```typescript
class User {
  constructor(
    private name: string,
    private email: string
  ) {}

  // User management
  updateEmail(email: string) {
    this.email = email
  }

  // Email sending (different responsibility!)
  sendWelcomeEmail() {
    const smtp = new SMTPClient()
    smtp.send(this.email, 'Welcome!')
  }

  // Database persistence (different responsibility!)
  save() {
    db.query('INSERT INTO users...')
  }

  // Report generation (different responsibility!)
  generateReport() {
    return `User Report: ${this.name}`
  }
}
```

**Problems**:
- Changing email logic affects User class
- Changing database affects User class
- Changing reports affects User class
- Hard to test

### ✅ Good Example
```typescript
// Single responsibility: User data and behavior
class User {
  constructor(
    private name: string,
    private email: string
  ) {}

  updateEmail(email: string) {
    if (!email.includes('@')) {
      throw new Error('Invalid email')
    }
    this.email = email
  }

  getName(): string {
    return this.name
  }

  getEmail(): string {
    return this.email
  }
}

// Single responsibility: Sending emails
class EmailService {
  sendWelcomeEmail(user: User) {
    this.smtp.send(user.getEmail(), 'Welcome!')
  }
}

// Single responsibility: User persistence
class UserRepository {
  save(user: User) {
    db.query('INSERT INTO users...', user)
  }
}

// Single responsibility: Report generation
class UserReportGenerator {
  generate(user: User): string {
    return `User Report: ${user.getName()}`
  }
}
```

---

## O - Open/Closed Principle

**Definition**: Open for extension, closed for modification

### ❌ Bad Example
```typescript
class PaymentProcessor {
  processPayment(type: string, amount: number) {
    if (type === 'credit_card') {
      // Process credit card
      console.log('Processing credit card...')
    } else if (type === 'paypal') {
      // Process PayPal
      console.log('Processing PayPal...')
    } else if (type === 'crypto') {  // Need to modify class!
      // Process crypto
      console.log('Processing crypto...')
    }
  }
}
```

**Problem**: Adding new payment method requires modifying existing code

### ✅ Good Example
```typescript
// Interface
interface PaymentMethod {
  process(amount: number): void
}

// Implementations (can add more without modifying existing)
class CreditCardPayment implements PaymentMethod {
  process(amount: number) {
    console.log(`Processing $${amount} via credit card`)
  }
}

class PayPalPayment implements PaymentMethod {
  process(amount: number) {
    console.log(`Processing $${amount} via PayPal`)
  }
}

class CryptoPayment implements PaymentMethod {
  process(amount: number) {
    console.log(`Processing $${amount} via crypto`)
  }
}

// Processor doesn't need modification
class PaymentProcessor {
  processPayment(method: PaymentMethod, amount: number) {
    method.process(amount)
  }
}

// Usage
const processor = new PaymentProcessor()
processor.processPayment(new CreditCardPayment(), 100)
processor.processPayment(new PayPalPayment(), 200)
processor.processPayment(new CryptoPayment(), 300)  // New method!
```

---

## L - Liskov Substitution Principle

**Definition**: Subtypes must be substitutable for their base types

### ❌ Bad Example
```typescript
class Bird {
  fly() {
    console.log('Flying...')
  }
}

class Penguin extends Bird {
  fly() {
    throw new Error('Penguins cannot fly!')  // Breaks LSP!
  }
}

// Problem: Code expecting Bird will break with Penguin
function makeBirdFly(bird: Bird) {
  bird.fly()  // Throws error if bird is Penguin!
}

makeBirdFly(new Bird())     // ✓ Works
makeBirdFly(new Penguin())  // ✗ Throws error
```

### ✅ Good Example
```typescript
class Bird {
  eat() {
    console.log('Eating...')
  }
}

class FlyingBird extends Bird {
  fly() {
    console.log('Flying...')
  }
}

class Penguin extends Bird {
  swim() {
    console.log('Swimming...')
  }
}

class Eagle extends FlyingBird {
  // Inherits fly()
}

// Now substitution works correctly
function makeBirdEat(bird: Bird) {
  bird.eat()  // All birds can eat
}

function makeFlyingBirdFly(bird: FlyingBird) {
  bird.fly()  // Only flying birds
}

makeBirdEat(new Penguin())  // ✓ Works
makeBirdEat(new Eagle())    // ✓ Works
makeFlyingBirdFly(new Eagle())  // ✓ Works
// makeFlyingBirdFly(new Penguin())  // Won't compile (type error)
```

---

## I - Interface Segregation Principle

**Definition**: Many client-specific interfaces are better than one general-purpose interface

### ❌ Bad Example
```typescript
interface Worker {
  work(): void
  eat(): void
  sleep(): void
}

// Human worker implements all
class HumanWorker implements Worker {
  work() { console.log('Working...') }
  eat() { console.log('Eating...') }
  sleep() { console.log('Sleeping...') }
}

// Robot worker forced to implement unnecessary methods
class RobotWorker implements Worker {
  work() { console.log('Working...') }
  eat() { /* Robots don't eat! */ }
  sleep() { /* Robots don't sleep! */ }
}
```

### ✅ Good Example
```typescript
// Segregated interfaces
interface Workable {
  work(): void
}

interface Eatable {
  eat(): void
}

interface Sleepable {
  sleep(): void
}

// Human implements what it needs
class HumanWorker implements Workable, Eatable, Sleepable {
  work() { console.log('Working...') }
  eat() { console.log('Eating...') }
  sleep() { console.log('Sleeping...') }
}

// Robot only implements what it needs
class RobotWorker implements Workable {
  work() { console.log('Working...') }
  // No need to implement eat() or sleep()
}

// Usage is specific
function makeWork(worker: Workable) {
  worker.work()
}

function feedWorker(worker: Eatable) {
  worker.eat()
}

makeWork(new HumanWorker())  // ✓
makeWork(new RobotWorker())  // ✓
feedWorker(new HumanWorker()) // ✓
// feedWorker(new RobotWorker()) // Won't compile
```

---

## D - Dependency Inversion Principle

**Definition**: Depend on abstractions, not on concretions

### ❌ Bad Example
```typescript
// High-level module depends on low-level module
class MySQLDatabase {
  save(data: string) {
    console.log(`Saving to MySQL: ${data}`)
  }
}

class UserService {
  private database = new MySQLDatabase()  // Direct dependency!

  saveUser(user: User) {
    this.database.save(user.name)
  }
}

// Problem: Cannot easily switch to PostgreSQL or MongoDB
```

### ✅ Good Example
```typescript
// Abstraction
interface Database {
  save(data: string): void
}

// Low-level modules implement abstraction
class MySQLDatabase implements Database {
  save(data: string) {
    console.log(`Saving to MySQL: ${data}`)
  }
}

class PostgreSQLDatabase implements Database {
  save(data: string) {
    console.log(`Saving to PostgreSQL: ${data}`)
  }
}

class MongoDBDatabase implements Database {
  save(data: string) {
    console.log(`Saving to MongoDB: ${data}`)
  }
}

// High-level module depends on abstraction
class UserService {
  constructor(
    private database: Database  // Depends on interface!
  ) {}

  saveUser(user: User) {
    this.database.save(user.name)
  }
}

// Dependency injection at composition root
const mysqlDb = new MySQLDatabase()
const userService = new UserService(mysqlDb)

// Easy to switch!
const mongoDb = new MongoDBDatabase()
const userService2 = new UserService(mongoDb)
```

---

## All Principles Combined

```typescript
// S - Single Responsibility
class Order {
  constructor(private items: OrderItem[]) {}

  addItem(item: OrderItem) { /* ... */ }
  getTotalAmount(): number { /* ... */ }
}

// O - Open/Closed
interface PaymentProcessor {
  process(amount: number): void
}

class StripeProcessor implements PaymentProcessor {
  process(amount: number) { /* ... */ }
}

// L - Liskov Substitution
function processPayment(processor: PaymentProcessor, amount: number) {
  processor.process(amount)  // Any PaymentProcessor works
}

// I - Interface Segregation
interface Orderable {
  place(): void
}

interface Cancelable {
  cancel(): void
}

interface Refundable {
  refund(): void
}

// D - Dependency Inversion
class OrderService {
  constructor(
    private orderRepo: OrderRepository,  // Interface, not concrete
    private paymentProcessor: PaymentProcessor  // Interface
  ) {}

  async placeOrder(order: Order) {
    await this.orderRepo.save(order)
    this.paymentProcessor.process(order.getTotalAmount())
  }
}
```

---

## Benefits of SOLID

✅ **Maintainability**: Easy to modify without breaking things
✅ **Testability**: Easy to mock dependencies
✅ **Flexibility**: Easy to swap implementations
✅ **Readability**: Clear, single-purpose classes
✅ **Reusability**: Components can be reused easily

---

## Quick Reference

| Principle | Question to Ask |
|-----------|-----------------|
| **SRP** | Does this class have only one reason to change? |
| **OCP** | Can I add new functionality without modifying existing code? |
| **LSP** | Can I replace this type with its subtype without breaking things? |
| **ISP** | Does this interface force clients to depend on methods they don't use? |
| **DIP** | Am I depending on abstractions or concrete implementations? |

---

**Remember**: SOLID principles are guidelines, not laws. Use them when they add value, not blindly.

**Created**: 2026-02-04
