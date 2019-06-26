package template

import (
	"bytes"
	"path/filepath"
	"text/template"

	"github.com/stakater/Konfigurator/pkg/template/funcs"
)

func newTemplate(name string) *template.Template {
	return template.New(name).Funcs(funcs.TemplateFuncs)
}

// ExecuteFile executes a template file located at path with the specified data
func ExecuteFile(path string, data interface{}) ([]byte, error) {
	template, err := newTemplate(filepath.Base(path)).ParseFiles(path)
	if err != nil {
		return nil, err
	}

	return executeTemplate(template, data)
}

// ExecuteString executes a template string with the specified data
func ExecuteString(text string, data interface{}) ([]byte, error) {
	template, err := newTemplate("stdin").Parse(text)
	if err != nil {
		return nil, err
	}

	return executeTemplate(template, data)
}

// Helper for ExecuteFile and ExecuteString - actually executes the template
func executeTemplate(template *template.Template, data interface{}) ([]byte, error) {
	var buffer bytes.Buffer
	if err := template.Execute(&buffer, data); err != nil {
		return nil, err
	}

	return buffer.Bytes(), nil
}
