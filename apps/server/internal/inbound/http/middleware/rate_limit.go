package middleware

import (
	"net/http"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
	"golang.org/x/time/rate"
)

func RateLimiter(period time.Duration, max int) gin.HandlerFunc {
	limiters := sync.Map{}
	return func(c *gin.Context) {
		ip := c.ClientIP()
		var limiter *rate.Limiter
		if v, ok := limiters.Load(ip); !ok {
			limiter = rate.NewLimiter(rate.Every(period), max)
			limiters.Store(ip, limiter)
		} else {
			limiter = v.(*rate.Limiter)
		}
		if limiter.Allow() {
			c.Next()
		} else {
			c.AbortWithStatus(http.StatusTooManyRequests)
		}
	}
}
