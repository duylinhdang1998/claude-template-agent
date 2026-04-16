# Clean Architecture - Complete Guide

## Overview

Clean Architecture separates software into layers with strict dependency rules, making business logic independent of frameworks, UI, and databases.

---

## The Dependency Rule

**CRITICAL**: Dependencies must only point inward

```
┌─────────────────────────────────────────┐
│     Frameworks & Drivers (Outermost)    │ ← UI, DB, Web
│  ┌───────────────────────────────────┐  │
│  │    Interface Adapters (Middle)    │  │ ← Controllers, Presenters
│  │  ┌─────────────────────────────┐  │  │
│  │  │  Use Cases (Application)    │  │  │ ← Business workflows
│  │  │  ┌───────────────────────┐  │  │  │
│  │  │  │  Entities (Innermost) │  │  │  │ ← Core business
│  │  │  └───────────────────────┘  │  │  │
│  │  └─────────────────────────────┘  │  │
│  └───────────────────────────────────┘  │
└─────────────────────────────────────────┘

Dependencies flow: Outside → Inside
Inner layers know NOTHING about outer layers
```

---

## Layer Breakdown

### 1. Entities (Core Domain)

**What**: Core business objects and rules

**Characteristics**:
- NO dependencies on anything
- Pure TypeScript/Python/Java
- Can be used in ANY application
- Contains enterprise-wide business rules

**Example (TypeScript)**:
```typescript
// entities/Order.ts
export class Order {
  private constructor(
    private readonly id: OrderId,
    private items: OrderItem[],
    private status: OrderStatus,
    private createdAt: Date
  ) {
    if (items.length === 0) {
      throw new DomainError('Order must have at least one item')
    }
  }

  static create(items: OrderItem[]): Order {
    return new Order(
      OrderId.generate(),
      items,
      OrderStatus.DRAFT,
      new Date()
    )
  }

  addItem(item: OrderItem): void {
    if (this.status !== OrderStatus.DRAFT) {
      throw new DomainError('Cannot add items to non-draft order')
    }
    this.items.push(item)
  }

  place(): void {
    if (this.items.length === 0) {
      throw new DomainError('Cannot place empty order')
    }
    this.status = OrderStatus.PLACED
  }

  getTotalAmount(): Money {
    return this.items.reduce(
      (sum, item) => sum.add(item.getPrice()),
      Money.zero()
    )
  }

  // No database logic!
  // No HTTP logic!
  // Pure business rules only
}
```

**Value Objects**:
```typescript
// value-objects/Money.ts
export class Money {
  private constructor(
    private readonly amount: number,
    private readonly currency: string
  ) {
    if (amount < 0) {
      throw new DomainError('Amount cannot be negative')
    }
  }

  static create(amount: number, currency = 'USD'): Money {
    return new Money(amount, currency)
  }

  add(other: Money): Money {
    if (this.currency !== other.currency) {
      throw new DomainError('Cannot add different currencies')
    }
    return new Money(this.amount + other.amount, this.currency)
  }

  equals(other: Money): boolean {
    return this.amount === other.amount &&
           this.currency === other.currency
  }
}
```

---

### 2. Use Cases (Application Layer)

**What**: Business workflows, orchestration

**Characteristics**:
- Depends ONLY on entities
- Uses abstractions (interfaces) for everything else
- Contains application-specific business rules
- Coordinates between entities

**Example**:
```typescript
// application/use-cases/CreateOrderUseCase.ts
export interface IOrderRepository {
  save(order: Order): Promise<void>
  findById(id: OrderId): Promise<Order | null>
}

export interface IEmailService {
  sendOrderConfirmation(order: Order): Promise<void>
}

export class CreateOrderUseCase {
  constructor(
    private readonly orderRepository: IOrderRepository,  // Interface!
    private readonly emailService: IEmailService        // Interface!
  ) {}

  async execute(command: CreateOrderCommand): Promise<OrderDto> {
    // 1. Validate input
    if (!command.items || command.items.length === 0) {
      throw new ValidationError('Items required')
    }

    // 2. Create entity (business logic is IN the entity)
    const orderItems = command.items.map(item =>
      OrderItem.create(item.productId, item.quantity, item.price)
    )
    const order = Order.create(orderItems)

    // 3. Place order (business logic again)
    order.place()

    // 4. Persist (through interface)
    await this.orderRepository.save(order)

    // 5. Side effects (through interface)
    await this.emailService.sendOrderConfirmation(order)

    // 6. Return DTO (data transfer object)
    return OrderDto.fromEntity(order)
  }
}
```

**DTOs (Data Transfer Objects)**:
```typescript
// application/dto/OrderDto.ts
export class OrderDto {
  constructor(
    public readonly id: string,
    public readonly items: OrderItemDto[],
    public readonly totalAmount: number,
    public readonly status: string
  ) {}

  static fromEntity(order: Order): OrderDto {
    return new OrderDto(
      order.getId().value,
      order.getItems().map(OrderItemDto.fromEntity),
      order.getTotalAmount().getAmount(),
      order.getStatus()
    )
  }
}
```

---

### 3. Interface Adapters

**What**: Convert data between use cases and external world

**Contains**:
- **Controllers**: HTTP request → Use case
- **Presenters**: Use case result → HTTP response
- **Gateways**: Interface implementations

**Example - Controller**:
```typescript
// presentation/api/controllers/OrderController.ts
export class OrderController {
  constructor(
    private readonly createOrderUseCase: CreateOrderUseCase
  ) {}

  async createOrder(req: Request, res: Response): Promise<void> {
    try {
      // 1. Map HTTP request to command
      const command = new CreateOrderCommand(
        req.body.items,
        req.user.id
      )

      // 2. Execute use case
      const orderDto = await this.createOrderUseCase.execute(command)

      // 3. Map DTO to HTTP response
      res.status(201).json({
        success: true,
        data: orderDto
      })
    } catch (error) {
      // Error handling
      if (error instanceof ValidationError) {
        res.status(400).json({ error: error.message })
      } else {
        res.status(500).json({ error: 'Internal server error' })
      }
    }
  }
}
```

**Example - Repository Implementation**:
```typescript
// infrastructure/persistence/PostgresOrderRepository.ts
export class PostgresOrderRepository implements IOrderRepository {
  constructor(private readonly db: Database) {}

  async save(order: Order): Promise<void> {
    // Convert domain entity to database row
    const orderRow = {
      id: order.getId().value,
      status: order.getStatus(),
      total_amount: order.getTotalAmount().getAmount(),
      created_at: order.getCreatedAt()
    }

    await this.db.query(
      'INSERT INTO orders (id, status, total_amount, created_at) VALUES ($1, $2, $3, $4)',
      [orderRow.id, orderRow.status, orderRow.total_amount, orderRow.created_at]
    )

    // Save order items
    for (const item of order.getItems()) {
      await this.saveOrderItem(order.getId(), item)
    }
  }

  async findById(id: OrderId): Promise<Order | null> {
    const row = await this.db.query(
      'SELECT * FROM orders WHERE id = $1',
      [id.value]
    )

    if (!row) return null

    // Convert database row to domain entity
    return OrderMapper.toDomain(row)
  }
}
```

---

### 4. Frameworks & Drivers

**What**: External tools (UI, DB, frameworks)

**Contains**:
- Express/FastAPI setup
- Database configuration
- External service integrations

**Example**:
```typescript
// main.ts (Composition Root)
import express from 'express'
import { Database } from './infrastructure/database'
import { PostgresOrderRepository } from './infrastructure/persistence/PostgresOrderRepository'
import { SendGridEmailService } from './infrastructure/email/SendGridEmailService'
import { CreateOrderUseCase } from './application/use-cases/CreateOrderUseCase'
import { OrderController } from './presentation/api/controllers/OrderController'

// 1. Setup infrastructure
const db = new Database(process.env.DATABASE_URL)
const orderRepository = new PostgresOrderRepository(db)
const emailService = new SendGridEmailService(process.env.SENDGRID_API_KEY)

// 2. Setup use cases (dependency injection)
const createOrderUseCase = new CreateOrderUseCase(
  orderRepository,
  emailService
)

// 3. Setup controllers
const orderController = new OrderController(createOrderUseCase)

// 4. Setup routes
const app = express()
app.post('/api/orders', (req, res) => orderController.createOrder(req, res))

app.listen(3000)
```

---

## Complete Folder Structure

```
src/
├── domain/                         # Layer 1: Entities
│   ├── entities/
│   │   ├── Order.ts
│   │   ├── OrderItem.ts
│   │   └── User.ts
│   ├── value-objects/
│   │   ├── Money.ts
│   │   ├── OrderId.ts
│   │   └── Email.ts
│   └── errors/
│       └── DomainError.ts
│
├── application/                    # Layer 2: Use Cases
│   ├── use-cases/
│   │   ├── CreateOrderUseCase.ts
│   │   ├── PlaceOrderUseCase.ts
│   │   └── CancelOrderUseCase.ts
│   ├── ports/                      # Interfaces
│   │   ├── IOrderRepository.ts
│   │   ├── IEmailService.ts
│   │   └── IPaymentGateway.ts
│   ├── dto/
│   │   └── OrderDto.ts
│   └── commands/
│       └── CreateOrderCommand.ts
│
├── infrastructure/                 # Layer 3: Adapters (Implementations)
│   ├── persistence/
│   │   ├── PostgresOrderRepository.ts
│   │   ├── mappers/
│   │   │   └── OrderMapper.ts
│   │   └── migrations/
│   ├── email/
│   │   └── SendGridEmailService.ts
│   └── payment/
│       └── StripePaymentGateway.ts
│
└── presentation/                   # Layer 4: Frameworks
    ├── api/
    │   ├── controllers/
    │   │   └── OrderController.ts
    │   ├── middleware/
    │   └── routes.ts
    └── web/
        └── views/
```

---

## Testing Benefits

### Test Entities (Pure Business Logic)
```typescript
describe('Order', () => {
  it('should calculate total correctly', () => {
    const items = [
      OrderItem.create(productId1, 2, Money.create(10)),
      OrderItem.create(productId2, 1, Money.create(20))
    ]
    const order = Order.create(items)

    expect(order.getTotalAmount()).toEqual(Money.create(40))
  })

  // No database! No HTTP! Pure logic!
})
```

### Test Use Cases (With Mocks)
```typescript
describe('CreateOrderUseCase', () => {
  it('should create order and send email', async () => {
    const mockRepo = {
      save: jest.fn()
    }
    const mockEmail = {
      sendOrderConfirmation: jest.fn()
    }

    const useCase = new CreateOrderUseCase(mockRepo, mockEmail)
    await useCase.execute(command)

    expect(mockRepo.save).toHaveBeenCalled()
    expect(mockEmail.sendOrderConfirmation).toHaveBeenCalled()
  })
})
```

---

## Benefits

✅ **Testability**: Test business logic without DB/UI
✅ **Framework Independence**: Swap Express for Fastify easily
✅ **Database Independence**: Swap PostgreSQL for MongoDB
✅ **UI Independence**: Same logic for Web, Mobile, CLI
✅ **Maintainability**: Clear separation, easy to understand
✅ **Flexibility**: Change infrastructure without touching business logic

---

## Common Mistakes

❌ **Entities depending on frameworks**:
```typescript
// BAD
class Order {
  @Column()  // Database annotation!
  id: number
}
```

❌ **Use cases depending on concrete implementations**:
```typescript
// BAD
class CreateOrderUseCase {
  constructor(
    private repo: PostgresOrderRepository  // Concrete class!
  ) {}
}
```

❌ **Domain logic in controllers**:
```typescript
// BAD
app.post('/orders', (req, res) => {
  const total = req.body.items.reduce((sum, item) => sum + item.price, 0)
  // Business logic in controller!
})
```

---

**Remember**: The goal is **flexibility and testability**, not perfection. Use clean architecture when it adds value, not just because it's "pure".

**Created**: 2026-02-04
