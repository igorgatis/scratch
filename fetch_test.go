package main

import (
	"fmt"
	"net/http"
	"net/http/httptest"
	"os"
	"os/exec"
	"path/filepath"
	"testing"
)

func TestFetch(t *testing.T) {
	// Start a local test server
	content := "Hello, World!"
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprint(w, content)
	}))
	defer server.Close()

	// Compile the fetch program
	// We assume fetch.go is in the current directory
	wd, err := os.Getwd()
	if err != nil {
		t.Fatalf("Failed to get current working directory: %v", err)
	}
	fetchSrc := filepath.Join(wd, "fetch.go")

	tmpDir := t.TempDir()
	fetchBin := filepath.Join(tmpDir, "fetch")
	cmd := exec.Command("go", "build", "-o", fetchBin, fetchSrc)
	if output, err := cmd.CombinedOutput(); err != nil {
		t.Fatalf("Failed to build fetch.go: %v\nOutput: %s", err, output)
	}

	// Run the fetch program
	outFile := filepath.Join(tmpDir, "output.txt")
	cmd = exec.Command(fetchBin, server.URL, outFile)
	if output, err := cmd.CombinedOutput(); err != nil {
		t.Fatalf("Failed to run fetch: %v\nOutput: %s", err, output)
	}

	// Verify the output file content
	got, err := os.ReadFile(outFile)
	if err != nil {
		t.Fatalf("Failed to read output file: %v", err)
	}

	if string(got) != content {
		t.Errorf("Expected content %q, got %q", content, string(got))
	}
}
