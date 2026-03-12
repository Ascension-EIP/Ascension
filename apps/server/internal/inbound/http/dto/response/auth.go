package response

import (
	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
)

type LoginResponse struct {
	RefreshToken string `json:"refresh_token"`
	AccessTokenResponse
	User *User `json:"user"`
}

func TokensUserToResponse(tokens *model.Tokens, user *model.User) *LoginResponse {
	return &LoginResponse{
		RefreshToken: tokens.RefreshToken.String(),
		AccessTokenResponse: AccessTokenResponse{
			AccessToken: tokens.AccessToken.Token,
			TokenType:   tokens.TokenType,
			ExpiresIn:   tokens.ExpiresIn,
		},
		User: UserToResponse(user),
	}
}

type AccessTokenResponse struct {
	AccessToken string `json:"access_token"`
	TokenType   string `json:"token_type"`
	ExpiresIn   uint   `json:"expires_in"`
}

func AccessTokenToResponse(token *model.AccessToken) *AccessTokenResponse {
	return &AccessTokenResponse{
		AccessToken: token.Token,
		TokenType:   token.TokenType,
		ExpiresIn:   token.ExpiresIn,
	}
}
