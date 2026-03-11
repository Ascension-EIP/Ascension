package response

type User struct {
	ID        string `json:"id"`
	Username  string `json:"username"`
	Type      string `json:"type"`
	CreatedAt string `json:"created_at"`
	UpdatedAt string `json:"updated_at"`
}
