package request

type (
	AuthForm struct {
		Username string `json:"username" binding:"required,min=3,max=32"`
		Password string `json:"password" binding:"required,min=8"`
	}
)
