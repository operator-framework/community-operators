package funcs

import (
	"path/filepath"
	"strconv"
	"strings"
	"text/template"
)

var TemplateFuncs = template.FuncMap{
	"distinctPodsByOwner": distinctPodsByOwner,
	"closest":             arrayClosest,
	"coalesce":            coalesce,
	"combine":             combine,
	"dir":                 dirList,
	"exists":              exists,
	"first":               first,
	"groupBy":             groupBy,
	"groupByKeys":         groupByKeys,
	"groupByMulti":        groupByMulti,
	"hasPrefix":           strings.HasPrefix,
	"hasSuffix":           strings.HasSuffix,
	"hasField":            hasField,
	"intersect":           intersect,
	"isValidJson":         isValidJSON,
	"json":                marshalJSON,
	"pathJoin":            filepath.Join,
	"keys":                keys,
	"last":                last,
	"dict":                dict,
	"mapContains":         mapContains,
	"parseBool":           strconv.ParseBool,
	"parseJson":           unmarshalJSON,
	"parseJsonSafe":       unmarshalJSONSafe,
	"replace":             strings.Replace,
	"split":               strings.Split,
	"splitN":              strings.SplitN,
	"strContains":         strings.Contains,
	"trim":                strings.TrimSpace,
	"trimPrefix":          strings.TrimPrefix,
	"trimSuffix":          strings.TrimSuffix,
	"values":              values,
	"when":                when,
	"where":               where,
	"whereExist":          whereExist,
	"whereNotExist":       whereNotExist,
	"whereAny":            whereAny,
	"whereAll":            whereAll,
}
