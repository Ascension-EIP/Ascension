// @date 2026-11-13
// @file rate_limit_test.go
// @brief Unit tests of the per client IP rate limiter.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package middleware

import (
	"net/http"
	"sync"
	"sync/atomic"
	"testing"
	"time"

	"github.com/gin-gonic/gin"
)

func rateLimitedEngine(period time.Duration, max int) (*gin.Engine, *atomic.Int32) {
	var calls atomic.Int32
	engine := gin.New()
	engine.GET("/", RateLimiter(period, max), func(c *gin.Context) {
		calls.Add(1)
		c.Status(http.StatusOK)
	})

	return engine, &calls
}

func TestRateLimiterAllowsABurstThenRefuses(t *testing.T) {
	engine, calls := rateLimitedEngine(time.Minute, 3)

	for i := range 3 {
		if rec := serve(engine, http.MethodGet, "/", "198.51.100.1:1000", nil); rec.Code != http.StatusOK {
			t.Fatalf("request %d: status = %d, want 200", i+1, rec.Code)
		}
	}
	if rec := serve(engine, http.MethodGet, "/", "198.51.100.1:1000", nil); rec.Code != http.StatusTooManyRequests {
		t.Fatalf("4th request: status = %d, want 429", rec.Code)
	}
	if got := calls.Load(); got != 3 {
		t.Errorf("handler ran %d times, want 3", got)
	}
}

func TestRateLimiterIsPerClientIP(t *testing.T) {
	engine, _ := rateLimitedEngine(time.Minute, 1)

	if rec := serve(engine, http.MethodGet, "/", "198.51.100.1:1000", nil); rec.Code != http.StatusOK {
		t.Fatalf("first IP: status = %d, want 200", rec.Code)
	}
	// Another port of the same IP shares the limit.
	if rec := serve(engine, http.MethodGet, "/", "198.51.100.1:2000", nil); rec.Code != http.StatusTooManyRequests {
		t.Fatalf("same IP, other port: status = %d, want 429", rec.Code)
	}
	if rec := serve(engine, http.MethodGet, "/", "198.51.100.2:1000", nil); rec.Code != http.StatusOK {
		t.Fatalf("second IP: status = %d, want 200", rec.Code)
	}
}

func TestRateLimiterRefills(t *testing.T) {
	engine, _ := rateLimitedEngine(20*time.Millisecond, 1)

	serve(engine, http.MethodGet, "/", "198.51.100.1:1000", nil)
	if rec := serve(engine, http.MethodGet, "/", "198.51.100.1:1000", nil); rec.Code != http.StatusTooManyRequests {
		t.Fatalf("second request: status = %d, want 429", rec.Code)
	}

	deadline := time.Now().Add(2 * time.Second)
	for time.Now().Before(deadline) {
		if rec := serve(engine, http.MethodGet, "/", "198.51.100.1:1000", nil); rec.Code == http.StatusOK {
			return
		}
		time.Sleep(5 * time.Millisecond)
	}
	t.Fatal("the limiter never refilled")
}

func TestRateLimitersAreIndependent(t *testing.T) {
	engine := gin.New()
	engine.GET("/a", RateLimiter(time.Minute, 1), func(c *gin.Context) { c.Status(http.StatusOK) })
	engine.GET("/b", RateLimiter(time.Minute, 1), func(c *gin.Context) { c.Status(http.StatusOK) })

	serve(engine, http.MethodGet, "/a", "198.51.100.1:1000", nil)
	if rec := serve(engine, http.MethodGet, "/b", "198.51.100.1:1000", nil); rec.Code != http.StatusOK {
		t.Errorf("/b after /a: status = %d, want 200", rec.Code)
	}
}

func TestRateLimiterIsSafeForConcurrentUse(t *testing.T) {
	engine, calls := rateLimitedEngine(time.Hour, 10)

	var wg sync.WaitGroup
	var refused atomic.Int32
	for range 50 {
		wg.Go(func() {
			if rec := serve(engine, http.MethodGet, "/", "198.51.100.1:1000", nil); rec.Code == http.StatusTooManyRequests {
				refused.Add(1)
			}
		})
	}
	wg.Wait()

	// The first requests of an IP may race to create its limiter, so a few more than the
	// burst can pass, but never all of them.
	if calls.Load() < 10 || refused.Load() == 0 {
		t.Errorf("allowed = %d, refused = %d, want at least 10 allowed and some refused", calls.Load(), refused.Load())
	}
}
