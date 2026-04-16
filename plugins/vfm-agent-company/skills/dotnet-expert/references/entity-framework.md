# Entity Framework Core

Advanced EF Core patterns and best practices.

## DbContext Setup

```csharp
public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options)
        : base(options) { }

    public DbSet<User> Users => Set<User>();
    public DbSet<Post> Posts => Set<Post>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        // Configure entities
        modelBuilder.Entity<User>(entity => {
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => e.Email).IsUnique();
            entity.Property(e => e.Name).HasMaxLength(200).IsRequired();

            // Relationships
            entity.HasMany(e => e.Posts)
                  .WithOne(e => e.Author)
                  .HasForeignKey(e => e.AuthorId)
                  .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<Post>(entity => {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Title).HasMaxLength(500).IsRequired();
            entity.HasIndex(e => e.CreatedAt);

            // Owned entity
            entity.OwnsOne(e => e.Metadata, metadata => {
                metadata.Property(m => m.Views).HasDefaultValue(0);
            });
        });

        // Global query filters (soft delete)
        modelBuilder.Entity<Post>().HasQueryFilter(p => !p.IsDeleted);
    }

    public override async Task<int> SaveChangesAsync(
        CancellationToken cancellationToken = default)
    {
        // Automatic audit fields
        foreach (var entry in ChangeTracker.Entries<IAuditable>())
        {
            switch (entry.State)
            {
                case EntityState.Added:
                    entry.Entity.CreatedAt = DateTime.UtcNow;
                    break;
                case EntityState.Modified:
                    entry.Entity.UpdatedAt = DateTime.UtcNow;
                    break;
            }
        }

        return await base.SaveChangesAsync(cancellationToken);
    }
}
```

## Repository Pattern

```csharp
public class UserRepository : IUserRepository
{
    private readonly AppDbContext _context;

    public UserRepository(AppDbContext context)
    {
        _context = context;
    }

    public async Task<User?> GetByIdAsync(string id)
    {
        return await _context.Users
            .Include(u => u.Posts.OrderByDescending(p => p.CreatedAt).Take(10))
            .AsSplitQuery() // Avoid cartesian explosion
            .FirstOrDefaultAsync(u => u.Id == id);
    }

    public async Task<List<User>> SearchAsync(string searchTerm, int page, int pageSize)
    {
        return await _context.Users
            .Where(u => EF.Functions.Like(u.Name, $"%{searchTerm}%") ||
                       EF.Functions.Like(u.Email, $"%{searchTerm}%"))
            .OrderBy(u => u.Name)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .AsNoTracking() // Read-only query
            .ToListAsync();
    }

    public async Task BulkUpdateAsync(List<User> users)
    {
        _context.Users.UpdateRange(users);
        await _context.SaveChangesAsync();
    }
}
```

## Best Practices

- **AsSplitQuery()**: Avoid cartesian explosion with multiple includes
- **AsNoTracking()**: For read-only queries
- **Global query filters**: Soft delete pattern
- **Owned entities**: For value objects
- **Audit fields**: Automatic CreatedAt/UpdatedAt
