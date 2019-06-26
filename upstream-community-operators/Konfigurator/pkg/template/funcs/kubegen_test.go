package funcs

import (
	"reflect"
	"testing"
)

func TestCombine(t *testing.T) {
	array1 := []string{"first", "second", "third"}
	array2 := []string{"fourth", "fifth", "sixth"}
	array3, err := combine(array1, array2)
	if err != nil {
		t.Errorf("Combine failed with error %v", err)
	}
	if len(array3) != 6 {
		t.Errorf("Combine function failed for sliced")
	}

	primes := [6]int{2, 3, 5, 7, 11, 13}
	primeArray, err := combine(primes[1:4], primes[4:])
	if err != nil {
		t.Errorf("Combine failed with error %v", err)
	}

	if len(primeArray) != 5 {
		t.Errorf("Combine function failed for sliced")
	}
}

func TestValues(t *testing.T) {
	testMap := map[string]string{"firstKey": "firstValue", "secondKey": "secondValue", "thirdKey": "thirdValue"}
	result, err := values(testMap)
	if err != nil {
		t.Errorf("Values failed with err %v", err)
	}

	resultValue := reflect.ValueOf(result)

	if resultValue.Len() != 3 {
		t.Errorf("Values should return 3 values")
	}

	for i := 0; i < resultValue.Len(); i++ {
		val := resultValue.Index(i).Interface()
		if val != "firstValue" && val != "secondValue" && val != "thirdValue" {
			t.Errorf("Values returned unexpected value %s", val)
		}
	}
}
