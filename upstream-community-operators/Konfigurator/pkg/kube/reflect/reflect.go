package reflect

import (
	"strings"

	"github.com/fatih/structs"
)

func AssignValueTo(target interface{}, field string, value interface{}) error {
	targetStruct := structs.New(target)

	nestedFields := strings.Split(field, ".")

	finalField := targetStruct.Field(nestedFields[0])

	for i := 1; i < len(nestedFields); i++ {
		finalField = finalField.Field(nestedFields[i])
	}

	if err := finalField.Set(value); err != nil {
		return err
	}

	return nil
}
