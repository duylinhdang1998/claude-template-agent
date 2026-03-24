# Spring Data JPA

Advanced repository patterns.

## Repository Interface

```java
@Repository
public interface VideoRepository extends JpaRepository<Video, String> {

    // Query methods (Spring Data magic)
    Optional<Video> findByTitle(String title);

    List<Video> findByTitleContainingIgnoreCase(String title);

    @Query("SELECT v FROM Video v WHERE v.title LIKE %:query% OR v.description LIKE %:query%")
    Page<Video> searchByTitle(@Param("query") String query, Pageable pageable);

    // Native query for performance
    @Query(value = """
        SELECT * FROM videos v
        WHERE v.created_at >= NOW() - INTERVAL '7 days'
        ORDER BY v.view_count DESC
        LIMIT :limit
        """, nativeQuery = true)
    List<Video> findTrendingVideos(@Param("limit") int limit);

    // Batch operations
    @Modifying
    @Query("UPDATE Video v SET v.viewCount = v.viewCount + 1 WHERE v.id = :id")
    void incrementViewCount(@Param("id") String id);
}
```

## Entity

```java
@Entity
@Table(name = "videos", indexes = {
    @Index(name = "idx_user_id", columnList = "user_id"),
    @Index(name = "idx_created_at", columnList = "created_at")
})
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Video {

    @Id
    private String id;

    @Column(nullable = false, length = 200)
    private String title;

    @Column(length = 2000)
    private String description;

    @Column(name = "duration_seconds", nullable = false)
    private Integer durationSeconds;

    @Column(name = "view_count")
    private Long viewCount = 0L;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }
}
```
