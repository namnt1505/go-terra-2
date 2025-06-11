package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strings"
)

// Global variable để lưu key value
var globalKeyValue string

func main() {
	http.HandleFunc("/", handler)

	// Debug: print current working directory
	wd, _ := os.Getwd()
	log.Printf("Current working directory: %s", wd)

	// Try different paths
	envPaths := []string{
		"../../env.yaml",
		"../../../env.yaml", // Thử path khác
		filepath.Join(wd, "..", "..", "env.yaml"),
		"/Users/namnt/Poc/tera-go/env.yaml", // Absolute path
	}

	var keyValue string
	found := false

	for _, envPath := range envPaths {
		log.Printf("Trying path: %s", envPath)
		data, err := os.ReadFile(envPath)
		if err != nil {
			log.Printf("Failed to read %s: %v", envPath, err)
			continue
		}

		log.Printf("Successfully read env file from: %s", envPath)
		// Simple parsing for KEY variable
		content := string(data)
		for _, line := range strings.Split(content, "\n") {
			if strings.HasPrefix(strings.TrimSpace(line), "KEY:") {
				keyValue = strings.TrimSpace(strings.TrimPrefix(strings.TrimSpace(line), "KEY:"))
				// Remove quotes if present
				keyValue = strings.Trim(keyValue, `"`)
				log.Printf("KEY value: %s", keyValue)
				found = true
				break
			}
		}
		if found {
			break
		}
	}

	if !found {
		log.Printf("Could not find or read env.yaml file")
		globalKeyValue = "KEY_NOT_FOUND"
	} else {
		globalKeyValue = keyValue
	}

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Printf("Listening on port %s", port)
	if err := http.ListenAndServe(fmt.Sprintf(":%s", port), nil); err != nil {
		log.Fatal(err)
	}
}

func handler(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(w, "Hello 123, World from App Engine Go API!\nKEY: %s", globalKeyValue)
}