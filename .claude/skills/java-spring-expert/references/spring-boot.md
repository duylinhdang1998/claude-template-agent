# Spring Boot Application

Production Spring Boot 3 setup with Netflix patterns.

## Application Configuration

```yaml
# application.yml
spring:
  application:
    name: video-service
  profiles:
    active: ${ENVIRONMENT:dev}

  datasource:
    url: jdbc:postgresql://localhost:5432/videos
    username: ${DB_USER}
    password: ${DB_PASSWORD}
    hikari:
      maximum-pool-size: 20
      minimum-idle: 5
      connection-timeout: 30000

  jpa:
    hibernate:
      ddl-auto: validate
    properties:
      hibernate:
        dialect: org.hibernate.dialect.PostgreSQLDialect

  cache:
    type: redis
    redis:
      time-to-live: 300000

server:
  port: 8080
  compression:
    enabled: true

management:
  endpoints:
    web:
      exposure:
        include: health,metrics,prometheus

resilience4j:
  circuitbreaker:
    instances:
      videoService:
        slidingWindowSize: 100
        failureRateThreshold: 50
        waitDurationInOpenState: 10000
```

## REST Controller

```java
@RestController
@RequestMapping("/api/v1/videos")
@Validated
public class VideoController {

    private final VideoService videoService;

    @Autowired
    public VideoController(VideoService videoService) {
        this.videoService = videoService;
    }

    @GetMapping("/{id}")
    @ResponseStatus(HttpStatus.OK)
    public ResponseEntity<VideoDto> getVideo(@PathVariable String id) {
        return videoService.findById(id)
            .map(ResponseEntity::ok)
            .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public ResponseEntity<VideoDto> createVideo(
            @Valid @RequestBody CreateVideoRequest request) {

        VideoDto video = videoService.createVideo(request);

        return ResponseEntity
            .created(URI.create("/api/v1/videos/" + video.getId()))
            .body(video);
    }

    @GetMapping("/search")
    public Page<VideoDto> searchVideos(
            @RequestParam String query,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {

        Pageable pageable = PageRequest.of(page, size);
        return videoService.search(query, pageable);
    }
}
```

## Service Layer with Resilience

```java
@Service
@Slf4j
public class VideoService {

    private final VideoRepository videoRepository;
    private final RecommendationClient recommendationClient;

    @Cacheable(value = "videos", key = "#id")
    public Optional<VideoDto> findById(String id) {
        log.info("Fetching video: {}", id);
        return videoRepository.findById(id).map(this::toDto);
    }

    @CircuitBreaker(name = "videoService", fallbackMethod = "getDefaultRecommendations")
    @Retry(name = "videoService")
    public List<VideoDto> getRecommendations(String userId) {
        List<String> videoIds = recommendationClient.getRecommendations(userId);
        return videoRepository.findAllById(videoIds)
            .stream()
            .map(this::toDto)
            .collect(Collectors.toList());
    }

    // Fallback method
    private List<VideoDto> getDefaultRecommendations(String userId, Throwable t) {
        log.warn("Using fallback recommendations: {}", t.getMessage());
        return videoRepository.findTrendingVideos(PageRequest.of(0, 10))
            .stream()
            .map(this::toDto)
            .collect(Collectors.toList());
    }
}
```
