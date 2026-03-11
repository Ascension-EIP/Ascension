package request

type (
	CreateUser struct {
		Username string `json:"username" binding:"required,min=3,max=32"`
		Password string `json:"password" binding:"required,min=8"`
		Type     string `json:"type" binding:"required,oneof=user admin"`
	}

	UpdateUser struct {
		Username string `json:"username" binding:"omitempty,min=3,max=32"`
		Password string `json:"password" binding:"omitempty,min=8"`
		Type     string `json:"type" binding:"omitempty,oneof=user admin"`
	}
)
