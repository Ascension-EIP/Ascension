// @date 2026-03-11
// @file error.go
// @brief File description.
// @project Ascension
// @author DimitriLaPoudre <lou.pellegrino@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package response

type Error struct {
	Message string `json:"error"`
}

func NewError(err error) Error {
	return Error{
		Message: err.Error(),
	}
}
