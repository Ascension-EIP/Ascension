// @date 2026-11-12
// @file optional.go
// @brief Optional JSON field that tells an absent field apart from an explicit null.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package request

import "encoding/json"

// Optional is a JSON field of a partial update. encoding/json decodes both an absent
// field and null into a nil pointer, so a pointer cannot tell "leave unchanged" from
// "clear". Optional can: Set is false when the field is absent, and Value is nil when
// the field is null.
type Optional[T any] struct {
	Set   bool
	Value *T
}

// UnmarshalJSON marks the field as set and decodes its value; null leaves Value nil.
// encoding/json calls it for null too, and never for an absent field.
func (o *Optional[T]) UnmarshalJSON(data []byte) error {
	o.Set = true
	o.Value = nil

	if string(data) == "null" {
		return nil
	}

	var value T
	if err := json.Unmarshal(data, &value); err != nil {
		return err
	}
	o.Value = &value

	return nil
}

// Patch returns the field in the double-pointer form of the model partials:
// nil when absent, a pointer to nil when null, a pointer to the value otherwise.
func (o Optional[T]) Patch() **T {
	if !o.Set {
		return nil
	}

	value := o.Value
	return &value
}
