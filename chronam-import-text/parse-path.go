package main

import (
	"io/ioutil"
	"path/filepath"
	"regexp"
	"strings"
)

func getDocid(path string, base string) string {
	docid := filepath.Dir(strings.Replace(path, base+"/", "", 1)) + "/"
	return docid
}

func getMetadata(docid string) (lccn, date, page string) {
	s := strings.Split(docid, "/")
	lccn = s[0]
	date = s[1]
	re := regexp.MustCompile("\\d+")
	page = re.FindString(s[3])
	return
}

func getText(path string) (string, error) {
	b, err := ioutil.ReadFile(path)
	if err != nil {
		return "", err
	}
	text := string(b)
	return text, nil
}
