# Domain-Driven Design (DDD) - Complete Guide

## Overview

DDD is about modeling complex business domains accurately using patterns and practices that align software with business reality.

---

## Core Concepts

### 1. Ubiquitous Language

**What**: Shared vocabulary between developers and domain experts

**Example (E-commerce)**:
- Domain Expert says: "Customer places an **Order** with **Line Items**"
- Code says: `Order` class with `LineItem[]` property
- NOT: `ShoppingCart` with `CartEntry[]` (different language!)

**Rule**: If domain expert wouldn't say it, don't name it that way in code

---

### 2. Bounded Contexts

**What**: Explicit boundaries around domain models

**Example (E-commerce Platform)**:
```
┌─────────────────┐  ┌──────────────────┐  ┌─────────────────┐
│ Catalog Context │  │  Order Context   │  │ Shipping Context│
│                 │  │                  │  │                 │
│ Product (rich)  │  │ Product (simple) │  │ Package         │
│ - description   │  │ - id, name       │  │ - tracking #    │
│ - images        │  │ - price          │  │ - address       │
│ - reviews       │  │                  │  │ - status        │
└─────────────────┘  └──────────────────┘  └─────────────────┘
```

**Key Insight**: "Product" means different things in different contexts!

---

### 3. Entities

**What**: Objects with unique identity and lifecycle

**Characteristics**:
- Has identity (ID)
- Mutable
- Identity persists through changes
- Equality = same ID

**Example**:
```typescript
class Order {
  constructor(
    private readonly id: OrderId,  // Identity
    private items: OrderItem[],    // Can change
    private status: OrderStatus    // Can change
  ) {}

  equals(other: Order): boolean {
    return this.id.equals(other.id)  // Compare by ID only
  }
}
```

---

### 4. Value Objects

**What**: Objects defined entirely by their attributes

**Characteristics**:
- No identity
- Immutable
- Equality = all attributes equal
- Can be shared/reused

**Examples**:
```typescript
// Money is a Value Object
class Money {
  constructor(
    private readonly amount: number,
    private readonly currency: string
  ) {
    Object.freeze(this)  // Immutable
  }

  add(other: Money): Money {
    // Returns NEW money, doesn't modify this
    return new Money(this.amount + other.amount, this.currency)
  }

  equals(other: Money): boolean {
    return this.amount === other.amount &&
           this.currency === other.currency
  }
}

// Address is a Value Object
class Address {
  constructor(
    private readonly street: string,
    private readonly city: string,
    private readonly zipCode: string
  ) {
    Object.freeze(this)
  }
}

// Email is a Value Object
class Email {
  private constructor(private readonly value: string) {}

  static create(email: string): Email {
    if (!email.includes('@')) {
      throw new Error('Invalid email')
    }
    return new Email(email)
  }
}
```

---

### 5. Aggregates

**What**: Cluster of entities/value objects treated as one unit

**Purpose**: Maintain consistency and enforce business rules

**Rules**:
- One entity is the **Aggregate Root** (entry point)
- External objects can only reference the root
- Root ensures invariants are maintained

**Example**:
```typescript
// Order is the Aggregate Root
class Order {  // ← Root
  private items: OrderItem[] = []  // ← Part of aggregate

  addItem(product: Product, quantity: number): void {
    // Root enforces business rules
    if (this.status !== OrderStatus.DRAFT) {
      throw new Error('Cannot add items to non-draft order')
    }

    const item = new OrderItem(product, quantity)
    this.items.push(item)

    // Root maintains invariants
    if (this.getTotalAmount().isGreaterThan(Money.create(10000))) {
      throw new Error('Order exceeds maximum amount')
    }
  }

  // External code CANNOT directly access items
  // Must go through root methods
}

// OrderItem is NOT an aggregate root
class OrderItem {  // ← Part of Order aggregate
  constructor(
    private product: Product,
    private quantity: number
  ) {}
}
```

**Aggregate Boundaries**:
```
┌───────────────────────────────┐
│  Order Aggregate              │
│  ┌─────────────────────────┐  │
│  │ Order (Root)            │  │
│  │ - id                    │  │
│  │ - customerId            │  │
│  │ - items[]               │  │
│  │ - status                │  │
│  └─────────────────────────┘  │
│  ┌─────────────────────────┐  │
│  │ OrderItem               │  │
│  │ - productId             │  │
│  │ - quantity              │  │
│  │ - price                 │  │
│  └─────────────────────────┘  │
└───────────────────────────────┘

External code:
✅ order.addItem(product, 2)
❌ order.items[0].quantity = 5  // Direct access forbidden!
```

---

### 6. Domain Events

**What**: Something that happened in the domain

**Characteristics**:
- Past tense naming (`OrderPlaced`, not `PlaceOrder`)
- Immutable
- Contains data about what happened
- Published after transaction succeeds

**Example**:
```typescript
// Domain Event
class OrderPlaced {
  constructor(
    public readonly orderId: OrderId,
    public readonly customerId: CustomerId,
    public readonly occurredAt: Date
  ) {
    Object.freeze(this)
  }
}

// Entity publishes events
class Order {
  private domainEvents: DomainEvent[] = []

  place(): void {
    if (this.items.length === 0) {
      throw new Error('Cannot place empty order')
    }

    this.status = OrderStatus.PLACED

    // Record that event occurred
    this.domainEvents.push(
      new OrderPlaced(this.id, this.customerId, new Date())
    )
  }

  getDomainEvents(): DomainEvent[] {
    return [...this.domainEvents]
  }

  clearDomainEvents(): void {
    this.domainEvents = []
  }
}

// Use case publishes events
class PlaceOrderUseCase {
  async execute(orderId: OrderId): Promise<void> {
    const order = await this.orderRepository.findById(orderId)

    order.place()  // Event recorded internally

    await this.orderRepository.save(order)

    // Publish events after save succeeds
    const events = order.getDomainEvents()
    for (const event of events) {
      await this.eventPublisher.publish(event)
    }

    order.clearDomainEvents()
  }
}
```

---

### 7. Repositories

**What**: Collection-like interface for accessing aggregates

**Purpose**: Abstract persistence details from domain

**Example**:
```typescript
// Repository interface (in domain layer)
interface IOrderRepository {
  findById(id: OrderId): Promise<Order | null>
  save(order: Order): Promise<void>
  findByCustomerId(customerId: CustomerId): Promise<Order[]>
}

// Usage in domain service
class OrderService {
  constructor(private orderRepository: IOrderRepository) {}

  async getCustomerOrders(customerId: CustomerId): Promise<Order[]> {
    return await this.orderRepository.findByCustomerId(customerId)
    // Domain doesn't know if data comes from PostgreSQL, MongoDB, or memory
  }
}
```

---

### 8. Domain Services

**What**: Operations that don't belong to any entity

**When to Use**:
- Operation involves multiple entities
- Operation doesn't naturally belong to one entity
- Stateless operation

**Example**:
```typescript
// Doesn't belong in Order or Customer
class OrderPricingService {
  calculateDiscount(order: Order, customer: Customer): Money {
    if (customer.isPremium()) {
      return order.getTotalAmount().multiply(0.1)  // 10% discount
    }

    if (order.getTotalAmount().isGreaterThan(Money.create(100))) {
      return Money.create(10)  // $10 off
    }

    return Money.zero()
  }
}
```

---

## Folder Structure Example

```
src/
├── domain/
│   ├── model/
│   │   ├── order/
│   │   │   ├── Order.ts              # Aggregate root
│   │   │   ├── OrderItem.ts          # Entity
│   │   │   ├── OrderStatus.ts        # Enum/Value Object
│   │   │   └── OrderId.ts            # Value Object (ID)
│   │   └── customer/
│   │       ├── Customer.ts
│   │       ├── CustomerId.ts
│   │       └── Email.ts              # Value Object
│   │
│   ├── events/
│   │   ├── OrderPlaced.ts
│   │   └── OrderCancelled.ts
│   │
│   ├── repositories/                  # Interfaces
│   │   ├── IOrderRepository.ts
│   │   └── ICustomerRepository.ts
│   │
│   └── services/
│       └── OrderPricingService.ts
│
├── application/
│   ├── commands/
│   │   └── PlaceOrderCommand.ts
│   └── handlers/
│       └── PlaceOrderHandler.ts
│
└── infrastructure/
    ├── persistence/
    │   ├── OrderRepository.ts         # Implementation
    │   └── CustomerRepository.ts
    └── events/
        └── EventPublisher.ts
```

---

## When to Use DDD

✅ **Use DDD when**:
- Complex business logic
- Long-lived project (5+ years)
- Domain experts available
- Business rules change frequently
- Multiple bounded contexts

❌ **Don't use DDD when**:
- Simple CRUD application
- Technical problem (not business problem)
- Small team, short timeline
- Requirements very unclear

---

## DDD with Clean Architecture

```
┌─────────────────────────────────────┐
│         Infrastructure              │
│  (Persistence, External Services)   │
└──────────────┬──────────────────────┘
               │ implements
┌──────────────▼──────────────────────┐
│         Application                 │
│  (Use Cases, Handlers)              │
└──────────────┬──────────────────────┘
               │ uses
┌──────────────▼──────────────────────┐
│         Domain (DDD)                │
│  ├── Entities & Aggregates          │
│  ├── Value Objects                  │
│  ├── Domain Events                  │
│  ├── Domain Services                │
│  └── Repository Interfaces          │
└─────────────────────────────────────┘
```

---

## Best Practices

1. **Start with Ubiquitous Language**: Talk to domain experts first
2. **Identify Bounded Contexts**: Don't create one giant model
3. **Model Behavior, Not Data**: Entities DO things, they're not just data containers
4. **Protect Invariants**: Use aggregates to enforce business rules
5. **Use Value Objects**: Lots of them! They reduce bugs
6. **Keep Aggregates Small**: Easier to maintain, better performance

---

## Example: E-commerce Order

```typescript
// Value Objects
class Money { /* ... */ }
class OrderId { /* ... */ }
class ProductId { /* ... */ }

// Entities within aggregate
class OrderItem {
  constructor(
    private readonly productId: ProductId,
    private quantity: number,
    private readonly unitPrice: Money
  ) {}

  increaseQuantity(amount: number): void {
    this.quantity += amount
  }

  getTotalPrice(): Money {
    return this.unitPrice.multiply(this.quantity)
  }
}

// Aggregate Root
class Order {
  private items: OrderItem[] = []
  private status: OrderStatus = OrderStatus.DRAFT

  constructor(
    private readonly id: OrderId,
    private readonly customerId: CustomerId
  ) {}

  addItem(productId: ProductId, quantity: number, unitPrice: Money): void {
    // Enforce invariants
    if (this.status !== OrderStatus.DRAFT) {
      throw new DomainError('Cannot modify non-draft order')
    }

    const existingItem = this.items.find(i => i.productId.equals(productId))

    if (existingItem) {
      existingItem.increaseQuantity(quantity)
    } else {
      this.items.push(new OrderItem(productId, quantity, unitPrice))
    }

    // Business rule: max 10 items
    if (this.items.length > 10) {
      throw new DomainError('Order cannot have more than 10 items')
    }
  }

  place(): void {
    // Enforce invariants
    if (this.items.length === 0) {
      throw new DomainError('Cannot place empty order')
    }
    if (this.status !== OrderStatus.DRAFT) {
      throw new DomainError('Order already placed')
    }

    this.status = OrderStatus.PLACED

    // Domain event
    this.addDomainEvent(
      new OrderPlaced(this.id, this.getTotalAmount(), new Date())
    )
  }

  getTotalAmount(): Money {
    return this.items.reduce(
      (sum, item) => sum.add(item.getTotalPrice()),
      Money.zero()
    )
  }
}
```

---

**Remember**: DDD is about understanding the business, not just writing code. Spend time with domain experts!

**Created**: 2026-02-04
