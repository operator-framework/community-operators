package funcs

import (
	"bytes"
	"encoding/json"
	"fmt"
	"reflect"

	"k8s.io/api/core/v1"
)

// combine multiple slices into a single slice
func combine(slices ...interface{}) ([]interface{}, error) {
	var count int
	for _, slice := range slices {
		value := reflect.ValueOf(slice)
		if value.Kind() != reflect.Slice && value.Kind() != reflect.Array {
			return nil, fmt.Errorf("combine can only be called with slice types. Received: %v", value.Kind())
		}
		count += value.Len()
	}

	combined := make([]interface{}, 0, count)
	for _, slice := range slices {
		value := reflect.ValueOf(slice)
		for i := 0; i < value.Len(); i++ {
			combined = append(combined, value.Index(i).Interface())
		}
	}
	return combined, nil
}

// returns bool indicating whether the provided value contains the specified field
func hasField(input interface{}, field string) bool {
	return deepGet(input, field) != nil
}

func values(input interface{}) (interface{}, error) {
	if input == nil {
		return nil, nil
	}

	value := reflect.ValueOf(input)
	if value.Kind() != reflect.Map {
		return nil, fmt.Errorf("Cannot call values on a non-map value: %v", input)
	}

	keys := value.MapKeys()
	values := make([]interface{}, value.Len())
	for i := range keys {
		values[i] = value.MapIndex(keys[i]).Interface()
	}

	return values, nil
}

func marshalJSON(input interface{}) (string, error) {
	byteArray, err := json.Marshal(input)
	if err != nil {
		return "", err
	}
	return string(bytes.TrimRight(byteArray, "\n")), nil
}

func unmarshalJSON(input string) (interface{}, error) {
	var value interface{}
	if err := json.Unmarshal([]byte(input), &value); err != nil {
		return nil, err
	}
	return value, nil
}

// unmarshalJsonSafe is the same as unmarshalJson, but returns nil if
// json.Unmarshal returns an error
func unmarshalJSONSafe(input string) interface{} {
	var v interface{}
	if err := json.Unmarshal([]byte(input), &v); err != nil {
		return nil
	}
	return v
}

func isValidJSON(input string) bool {
	_, err := unmarshalJSON(input)
	return err == nil
}

func distinctPodsByOwner(pods []interface{}) []interface{} {
	dPods := make([]interface{}, 0)
	for _, p := range pods {
		if !podWithOwnerExists(dPods, p.(v1.Pod)) {
			dPods = append(dPods, p)
		}
	}
	return dPods
}

func podWithOwnerExists(pods []interface{}, pod v1.Pod) bool {
	for _, p := range pods {
		for _, owner := range p.(v1.Pod).ObjectMeta.OwnerReferences {
			for _, pOwner := range pod.ObjectMeta.OwnerReferences {
				// Namespace need to be same as well since owner with same name can exist in different namespaces
				if owner.Name == pOwner.Name && p.(v1.Pod).Namespace == pod.Namespace {
					return true
				}
			}
		}
	}
	return false
}
