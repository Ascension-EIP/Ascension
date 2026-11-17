// @date 2026-11-13
// @file fields_test.go
// @brief Test helpers: fill a model with distinct values and check a conversion copied every field.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package response

import (
	"fmt"
	"net/netip"
	"reflect"
	"testing"
	"time"
)

var fillBase = time.Date(2026, 11, 13, 0, 0, 0, 0, time.UTC)

// fillDistinct sets every exported field of the struct ptr points to, recursively, to a
// non-zero value that differs from its neighbours, so a swapped or forgotten field shows.
func fillDistinct(ptr any) {
	n := 0
	fillValue(reflect.ValueOf(ptr).Elem(), &n)
}

func fillValue(v reflect.Value, n *int) {
	*n++
	small := int64(*n%100 + 1)

	switch v.Type() {
	case reflect.TypeFor[time.Time]():
		v.Set(reflect.ValueOf(fillBase.Add(time.Duration(*n) * time.Hour)))
		return
	case reflect.TypeFor[netip.Addr]():
		v.Set(reflect.ValueOf(netip.AddrFrom4([4]byte{10, 0, 0, byte(small)})))
		return
	}

	switch v.Kind() {
	case reflect.String:
		v.SetString(fmt.Sprintf("value-%d", *n))
	case reflect.Int, reflect.Int8, reflect.Int16, reflect.Int32, reflect.Int64:
		v.SetInt(small)
	case reflect.Uint, reflect.Uint8, reflect.Uint16, reflect.Uint32, reflect.Uint64:
		v.SetUint(uint64(small))
	case reflect.Float32, reflect.Float64:
		v.SetFloat(float64(small) + 0.5)
	case reflect.Bool:
		v.SetBool(true)
	case reflect.Pointer:
		p := reflect.New(v.Type().Elem())
		fillValue(p.Elem(), n)
		v.Set(p)
	case reflect.Array:
		for i := range v.Len() {
			fillValue(v.Index(i), n)
		}
	case reflect.Slice:
		s := reflect.MakeSlice(v.Type(), 1, 1)
		fillValue(s.Index(0), n)
		v.Set(s)
	case reflect.Map:
		v.Set(reflect.MakeMap(v.Type()))
	case reflect.Struct:
		for i := range v.NumField() {
			if v.Type().Field(i).IsExported() {
				fillValue(v.Field(i), n)
			}
		}
	}
}

// checkFields fails for every exported field of out that is zero or that differs from
// the field of in with the same name, or with the name aliases gives. A field of out with
// no counterpart in in must be listed in aliases with an empty name to be skipped.
func checkFields(t *testing.T, in any, out any, aliases map[string]string) {
	t.Helper()

	inV, outV := reflect.ValueOf(in), reflect.ValueOf(out)
	for i := range outV.NumField() {
		field := outV.Type().Field(i)
		if !field.IsExported() {
			continue
		}

		name := field.Name
		if alias, ok := aliases[name]; ok {
			if alias == "" {
				continue
			}
			name = alias
		}

		src := inV.FieldByName(name)
		if !src.IsValid() {
			t.Errorf("%s: no field %s in %s to compare with", field.Name, name, inV.Type())
			continue
		}

		dst := outV.Field(i)
		if dst.IsZero() {
			t.Errorf("%s is zero: the conversion forgot it", field.Name)
			continue
		}
		if got, want := deref(dst), deref(src); got != want {
			t.Errorf("%s = %s, want %s", field.Name, got, want)
		}
	}
}

// deref formats the value behind any number of pointers.
func deref(v reflect.Value) string {
	for v.Kind() == reflect.Pointer {
		if v.IsNil() {
			return "<nil>"
		}
		v = v.Elem()
	}
	return fmt.Sprint(v.Interface())
}
