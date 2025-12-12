package main

import (
	"io"
	"net/http"
	"os"
)

func main() {
	resp, _ := http.Get(os.Args[1])
	file, _ := os.Create(os.Args[2])
	io.Copy(file, resp.Body)
}
