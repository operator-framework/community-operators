package funcs

import (
	"reflect"
	"testing"

	"github.com/sirupsen/logrus"
)

func TestArrayClosest(t *testing.T) {
	values := []string{"Test", "Test String", "Test Strings", "More Test Strings"}
	expected := "Test Strings"
	result := arrayClosest(values, "Multiple Test Strings")

	if expected != result {
		t.Errorf("TestArrayClosest failed expected '%s', result '%s'", expected, result)
	}

}

func TestCoalesce(t *testing.T) {
	expected := "FirstNonNullValue"
	value := "SecondNonNullValue"
	result := coalesce(nil, expected, nil, value)
	if expected != result {
		t.Errorf("TestArrayClosest failed expected '%s', result '%s'", expected, result)
	}
}

func TestDirList(t *testing.T) {
	expected := 3
	names, err := dirList(".")

	if err != nil {
		t.Errorf("TestDirList failed with err %v", err)
	}

	count := 0
	for _, fileName := range names {
		if fileName == "dockergen.go" || fileName == "funcs.go" || fileName == "kubegen.go" {
			count++
		}
	}

	if expected != count {
		t.Errorf("Number of files found are less than expected, expected: '%d', found: '%d'", expected, count)
	}
}

func TestFirst(t *testing.T) {
	input := []string{"first", "second", "third"}
	expected := "first"
	result := first(input)

	if expected != result {
		t.Errorf("First did not return the first element for array, expected: '%s', actual: '%s'", expected, result)
	}

	if result = first(nil); result != nil {
		t.Errorf("First should return nil if array is nil, expected: 'nil', actual: '%s'", result)
	}
}

func TestKeys(t *testing.T) {
	keysInterface, _ := keys(nil)
	if keysInterface != nil {
		t.Errorf("keys should return nil if array is nil, expected: 'nil', actual: '%s'", keysInterface)
	}

	keysInterface, _ = keys("test")
	if keysInterface != nil {
		t.Errorf("keys should return nil if its argument type is not map, expected: 'nil', actual: '%s'", keysInterface)
	}

	input := make(map[string]string)
	input["firstKey"] = "firstvalue"
	input["secondKey"] = "secondvalue"
	input["thirdKey"] = "thirdvalue"

	keysInterface, _ = keys(input)
	keysArray := InterfaceSlice(keysInterface)

	if len(keysArray) != 3 {
		t.Errorf("Number of keys are less than expected, expected: '3', actual: '%d'", len(keysArray))
	}

	for _, key := range keysArray {
		if input[key.(string)] != "firstvalue" && input[key.(string)] != "secondvalue" && input[key.(string)] != "thirdvalue" {
			t.Errorf("keys value is different than expected, actual: '%s'", input[key.(string)])
		}
	}
}

func TestLast(t *testing.T) {
	input := []string{"first", "second", "third"}
	expected := "third"
	result := last(input)

	if expected != result {
		t.Errorf("Last did not return the last element for array, expected: '%s', actual: '%s'", expected, result)
	}

	if result = last(nil); result != nil {
		t.Errorf("Last should return nil if array is nil, expected: 'nil', actual: '%s'", result)
	}

	if result = last([]string{}); result != nil {
		t.Errorf("Last should return nil if array length is zero, expected: 'nil', actual: '%s'", result)
	}
}

func TestMapContains(t *testing.T) {
	input := make(map[string]string)
	input["firstKey"] = "firstvalue"
	input["secondKey"] = "secondvalue"
	input["thirdKey"] = "thirdvalue"

	expected := true
	result := mapContains(input, "thirdKey")

	if expected != result {
		t.Errorf("MapContains should return true, since 'thirdKey' is present in the map, expected: '%v', actual: '%v'", expected, result)
	}
}

func TestWhen(t *testing.T) {
	firstValue := "first"
	secondValue := "first"
	if result := when(firstValue == secondValue, true, false); !result.(bool) {
		t.Errorf("'When' should return true, since initial condition is true, expected: '%v', actual: '%v'", true, result)
	}

	secondValue = "second"
	if result := when(firstValue == secondValue, true, false); result.(bool) {
		t.Errorf("'When' should return false, since initial condition is false, expected: '%v', actual: '%v'", false, result)
	}
}

func TestGetArrayValues(t *testing.T) {
	input := []string{"first", "second"}
	array, err := getArrayValues("TestGetArrayValues", input)

	if err != nil {
		t.Errorf("getArrayValues encountered an error '%v'", err)
	}

	for i := 0; i < array.Len(); i++ {
		v := reflect.Indirect(array.Index(i)).Interface()
		if v != "first" && v != "second" {
			t.Errorf("getArrayValues did not return correct values, expected: 'first' or 'second, found: '%v'", v)
		}
	}
}

func TestIntersect(t *testing.T) {
	firstInput := []string{"first", "second", "fourth"}
	secondInput := []string{"first", "second", "third"}

	result := intersect(firstInput, secondInput)

	if len(result) != 2 {
		t.Errorf("intersect did not return correct number of values, expected: '2', found: '%d'", len(result))
	}

	for _, value := range result {
		if value != "first" && value != "second" {
			t.Errorf("intersect did not return correct values, expected: 'first' or 'second, found: '%v'", value)
		}
	}
}

func TestExists(t *testing.T) {
	path := "../../template/funcs/funcs.go"
	result, _ := exists(path)
	if !result {
		t.Errorf("'exist' did not return correct value for path '%s', expected: 'true', found: '%v'", path, result)
	}
}

func TestStripPrefix(t *testing.T) {
	path := "../../template/funcs/funcs.go"
	expected := "template/funcs/funcs.go"
	result := stripPrefix(path, "../")
	if result != expected {
		t.Errorf("'stripPrefix' did not return correct value, expected: '%s', found: '%s'", expected, result)
	}
}

// InterfaceSlice converts an interface to an interface array
func InterfaceSlice(slice interface{}) []interface{} {
	s := reflect.ValueOf(slice)
	if s.Kind() != reflect.Slice {
		logrus.Errorf("InterfaceSlice() given a non-slice type")
	}

	ret := make([]interface{}, s.Len())

	for i := 0; i < s.Len(); i++ {
		ret[i] = s.Index(i).Interface()
	}

	return ret
}
