package response

import (
	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
)

type LoginResponse struct {
	AccessToken  string `json:"access_token"`
	RefreshToken string `json:"refresh_token"`
	TokenType    string `json:"token_type"`
	User         *User  `json:"user"`
}

func TokensUserToResponse(tokens *model.Tokens, user *model.User) *LoginResponse {
	return &LoginResponse{
		AccessToken:  tokens.AccessToken,
		RefreshToken: tokens.RefreshToken.String(),
		TokenType:    "Bearer",
		User:         UserToResponse(user),
	}
}
